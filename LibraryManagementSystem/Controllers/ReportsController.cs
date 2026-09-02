using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using LibraryManagementSystem.Data;
using LibraryManagementSystem.Models;
using LibraryManagementSystem.Services;
using LibraryManagementSystem.ViewModels;
using CsvHelper;
using System.Globalization;
using System.Text;

namespace LibraryManagementSystem.Controllers
{
    [Authorize(Roles = "Admin,Librarian")]
    public class ReportsController : Controller
    {
        private readonly ApplicationDbContext _context;
        private readonly IBorrowingService _borrowingService;
        private readonly IFineService _fineService;
        private readonly IBookService _bookService;

        public ReportsController(ApplicationDbContext context, IBorrowingService borrowingService,
            IFineService fineService, IBookService bookService)
        {
            _context = context;
            _borrowingService = borrowingService;
            _fineService = fineService;
            _bookService = bookService;
        }

        [HttpGet]
        public async Task<IActionResult> Index(string reportType = "issued", DateTime? fromDate = null,
            DateTime? toDate = null, int? categoryId = null, string? status = null)
        {
            ViewBag.ReportType = reportType;
            ViewBag.FromDate = fromDate;
            ViewBag.ToDate = toDate;
            ViewBag.CategoryId = categoryId;
            ViewBag.Status = status;
            ViewBag.Categories = await _context.Categories.OrderBy(c => c.Name)
                .Select(c => new SelectListItem { Value = c.CategoryId.ToString(), Text = c.Name }).ToListAsync();

            object reportData = reportType switch
            {
                "issued" => await GetIssuedReport(fromDate, toDate),
                "returned" => await GetReturnedReport(fromDate, toDate),
                "overdue" => await _borrowingService.GetOverdueBorrowingsAsync(),
                "mostBorrowed" => await _bookService.GetMostBorrowedAsync(20),
                "fines" => await GetFinesReport(fromDate, toDate, status),
                "byCategory" => await _bookService.GetBooksByCategoryAsync(),
                _ => new List<object>()
            };

            ViewBag.ReportData = reportData;
            return View();
        }

        [HttpGet]
        public async Task<IActionResult> ExportCsv(string reportType, DateTime? fromDate = null, DateTime? toDate = null)
        {
            var sb = new StringBuilder();
            using var writer = new StringWriter(sb);
            using var csv = new CsvWriter(writer, CultureInfo.InvariantCulture);

            switch (reportType)
            {
                case "issued":
                    var issued = await GetIssuedReport(fromDate, toDate);
                    csv.WriteRecords(issued.Select(b => new
                    {
                        User = b.User?.FullName, Book = b.BookCopy?.Book?.Title,
                        AccessionNumber = b.BookCopy?.AccessionNumber,
                        b.IssueDate, b.DueDate, Status = b.Status.ToString()
                    }));
                    break;
                case "overdue":
                    var overdue = await _borrowingService.GetOverdueBorrowingsAsync();
                    csv.WriteRecords(overdue.Select(b => new
                    {
                        User = b.User?.FullName, Book = b.BookCopy?.Book?.Title,
                        AccessionNumber = b.BookCopy?.AccessionNumber,
                        b.IssueDate, b.DueDate,
                        OverdueDays = (DateTime.UtcNow - b.DueDate).Days
                    }));
                    break;
                case "fines":
                    var fines = await GetFinesReport(fromDate, toDate, null);
                    csv.WriteRecords(fines.Select(f => new
                    {
                        User = f.User?.FullName, f.Amount, f.Reason,
                        f.IssuedDate, PaidDate = f.PaidDate?.ToString("yyyy-MM-dd"),
                        Status = f.Status.ToString()
                    }));
                    break;
                default:
                    return BadRequest("Invalid report type.");
            }

            var bytes = Encoding.UTF8.GetBytes(sb.ToString());
            return File(bytes, "text/csv", $"{reportType}_report_{DateTime.UtcNow:yyyyMMdd}.csv");
        }

        private async Task<List<Borrowing>> GetIssuedReport(DateTime? from, DateTime? to)
        {
            var query = _context.Borrowings
                .Include(b => b.User).Include(b => b.BookCopy).ThenInclude(c => c!.Book)
                .Where(b => b.Status == BorrowingStatus.Issued);
            if (from.HasValue) query = query.Where(b => b.IssueDate >= from.Value);
            if (to.HasValue) query = query.Where(b => b.IssueDate <= to.Value.AddDays(1));
            return await query.OrderByDescending(b => b.IssueDate).ToListAsync();
        }

        private async Task<List<Borrowing>> GetReturnedReport(DateTime? from, DateTime? to)
        {
            var query = _context.Borrowings
                .Include(b => b.User).Include(b => b.BookCopy).ThenInclude(c => c!.Book)
                .Where(b => b.Status == BorrowingStatus.Returned);
            if (from.HasValue) query = query.Where(b => b.ReturnDate >= from.Value);
            if (to.HasValue) query = query.Where(b => b.ReturnDate <= to.Value.AddDays(1));
            return await query.OrderByDescending(b => b.ReturnDate).ToListAsync();
        }

        private async Task<List<Fine>> GetFinesReport(DateTime? from, DateTime? to, string? status)
        {
            var query = _context.Fines.Include(f => f.User)
                .Include(f => f.Borrowing).ThenInclude(b => b!.BookCopy).ThenInclude(c => c!.Book)
                .AsQueryable();
            if (from.HasValue) query = query.Where(f => f.IssuedDate >= from.Value);
            if (to.HasValue) query = query.Where(f => f.IssuedDate <= to.Value.AddDays(1));
            if (Enum.TryParse<FineStatus>(status, out var s)) query = query.Where(f => f.Status == s);
            return await query.OrderByDescending(f => f.IssuedDate).ToListAsync();
        }
    }
}
