using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LibraryManagementSystem.Data;
using LibraryManagementSystem.Models;
using LibraryManagementSystem.Services;
using LibraryManagementSystem.ViewModels;

namespace LibraryManagementSystem.Controllers
{
    [Authorize(Roles = "Admin,Librarian")]
    public class BorrowingsController : Controller
    {
        private readonly IBorrowingService _borrowingService;
        private readonly IBookService _bookService;
        private readonly ILibrarySettingsService _settingsService;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly ApplicationDbContext _context;

        public BorrowingsController(IBorrowingService borrowingService, IBookService bookService,
            ILibrarySettingsService settingsService, UserManager<ApplicationUser> userManager,
            ApplicationDbContext context)
        {
            _borrowingService = borrowingService;
            _bookService = bookService;
            _settingsService = settingsService;
            _userManager = userManager;
            _context = context;
        }

        public async Task<IActionResult> Index(string? searchTerm, string? status, int page = 1)
        {
            BorrowingStatus? statusFilter = null;
            if (Enum.TryParse<BorrowingStatus>(status, out var s)) statusFilter = s;

            var (borrowings, total) = await _borrowingService.GetBorrowingsAsync(
                searchTerm: searchTerm, status: statusFilter, page: page);
            ViewBag.SearchTerm = searchTerm;
            ViewBag.Status = status;
            ViewBag.CurrentPage = page;
            ViewBag.TotalPages = (int)Math.Ceiling(total / 10.0);
            return View(borrowings);
        }

        public async Task<IActionResult> Overdue()
        {
            var overdue = await _borrowingService.GetOverdueBorrowingsAsync();
            return View(overdue);
        }

        [HttpGet]
        public IActionResult Issue()
        {
            return View(new IssueBookViewModel());
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Issue(IssueBookViewModel model)
        {
            if (!ModelState.IsValid) return View(model);

            var issuedBy = _userManager.GetUserId(User)!;
            var result = await _borrowingService.IssueBookAsync(model.UserId, model.BookCopyId, issuedBy,
                HttpContext.Connection.RemoteIpAddress?.ToString());

            if (result.Success)
            {
                TempData["Success"] = result.Message;
                return RedirectToAction("Index");
            }

            TempData["Error"] = result.Message;
            return View(model);
        }

        [HttpGet]
        public async Task<IActionResult> Return(int? id)
        {
            if (id == null) return View("ReturnSearch");

            var borrowing = await _borrowingService.GetByIdAsync(id.Value);
            if (borrowing == null) return NotFound();

            var settings = await _settingsService.GetSettingsAsync();
            var overdueDays = borrowing.DueDate < DateTime.UtcNow
                ? (int)(DateTime.UtcNow - borrowing.DueDate).TotalDays : 0;

            var model = new ReturnBookViewModel
            {
                BorrowingId = borrowing.BorrowingId,
                UserName = borrowing.User?.FullName ?? "",
                BookTitle = borrowing.BookCopy?.Book?.Title ?? "",
                AccessionNumber = borrowing.BookCopy?.AccessionNumber ?? "",
                IssueDate = borrowing.IssueDate,
                DueDate = borrowing.DueDate,
                OverdueDays = overdueDays,
                CalculatedFine = overdueDays * settings.FinePerDay,
                FinePerDay = settings.FinePerDay
            };
            return View(model);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ProcessReturn(int borrowingId, string? notes)
        {
            var returnedBy = _userManager.GetUserId(User)!;
            var result = await _borrowingService.ReturnBookAsync(borrowingId, returnedBy, notes,
                HttpContext.Connection.RemoteIpAddress?.ToString());

            TempData[result.Success ? "Success" : "Error"] = result.Message;
            return RedirectToAction("Index");
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Renew(int id)
        {
            var result = await _borrowingService.RenewBookAsync(id,
                HttpContext.Connection.RemoteIpAddress?.ToString());
            TempData[result.Success ? "Success" : "Error"] = result.Message;
            return RedirectToAction("Index");
        }

        // ── AJAX Endpoints ──────────────────────────────────────────
        [HttpGet]
        public async Task<IActionResult> SearchUsers(string q)
        {
            if (string.IsNullOrWhiteSpace(q)) return Json(new List<object>());
            var users = await _context.Users
                .Where(u => u.IsActive && (u.FullName.Contains(q) || u.Email!.Contains(q)))
                .Take(10)
                .Select(u => new { u.Id, u.FullName, u.Email })
                .ToListAsync();
            return Json(users);
        }

        [HttpGet]
        public async Task<IActionResult> SearchCopies(string q)
        {
            if (string.IsNullOrWhiteSpace(q)) return Json(new List<object>());
            var copies = await _context.BookCopies
                .Include(c => c.Book)
                .Where(c => c.Status == BookCopyStatus.Available &&
                    (c.AccessionNumber.Contains(q) || c.Barcode.Contains(q) || c.Book!.Title.Contains(q)))
                .Take(10)
                .Select(c => new { c.BookCopyId, c.AccessionNumber, c.Barcode, BookTitle = c.Book!.Title, c.Status })
                .ToListAsync();
            return Json(copies);
        }

        [HttpGet]
        public async Task<IActionResult> LookupBorrowing(string q)
        {
            if (string.IsNullOrWhiteSpace(q)) return Json(null);
            var borrowing = await _context.Borrowings
                .Include(b => b.User)
                .Include(b => b.BookCopy).ThenInclude(c => c!.Book)
                .Where(b => b.Status == BorrowingStatus.Issued &&
                    (b.BookCopy!.AccessionNumber.Contains(q) || b.BookCopy.Barcode.Contains(q)))
                .FirstOrDefaultAsync();

            if (borrowing == null) return Json(null);
            return Json(new
            {
                borrowing.BorrowingId,
                UserName = borrowing.User?.FullName,
                BookTitle = borrowing.BookCopy?.Book?.Title,
                AccessionNumber = borrowing.BookCopy?.AccessionNumber,
                IssueDate = borrowing.IssueDate.ToString("yyyy-MM-dd"),
                DueDate = borrowing.DueDate.ToString("yyyy-MM-dd")
            });
        }
    }
}
