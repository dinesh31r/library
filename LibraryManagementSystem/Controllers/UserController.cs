using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using LibraryManagementSystem.Models;
using LibraryManagementSystem.Services;
using LibraryManagementSystem.ViewModels;

namespace LibraryManagementSystem.Controllers
{
    [Authorize(Roles = "User")]
    public class UserController : Controller
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IBorrowingService _borrowingService;
        private readonly IFineService _fineService;
        private readonly IReservationService _reservationService;
        private readonly ILibrarySettingsService _settingsService;

        public UserController(UserManager<ApplicationUser> userManager,
            IBorrowingService borrowingService, IFineService fineService,
            IReservationService reservationService, ILibrarySettingsService settingsService)
        {
            _userManager = userManager;
            _borrowingService = borrowingService;
            _fineService = fineService;
            _reservationService = reservationService;
            _settingsService = settingsService;
        }

        public async Task<IActionResult> Dashboard()
        {
            var userId = _userManager.GetUserId(User)!;
            var settings = await _settingsService.GetSettingsAsync();
            var activeBorrowings = await _borrowingService.GetUserActiveBorrowingsAsync(userId);
            var reservations = await _reservationService.GetUserReservationsAsync(userId);
            var outstandingFines = await _fineService.GetUserOutstandingFinesAsync(userId);

            var alerts = new List<string>();
            foreach (var b in activeBorrowings)
            {
                var daysLeft = (b.DueDate - DateTime.UtcNow).Days;
                if (daysLeft < 0)
                    alerts.Add($"⚠️ '{b.BookCopy?.Book?.Title}' is overdue by {Math.Abs(daysLeft)} day(s)!");
                else if (daysLeft <= 2)
                    alerts.Add($"📅 '{b.BookCopy?.Book?.Title}' is due in {daysLeft} day(s).");
            }
            if (outstandingFines > 0)
                alerts.Add($"💰 You have an outstanding fine of ₹{outstandingFines:F2}.");

            var model = new UserDashboardViewModel
            {
                CurrentlyBorrowed = activeBorrowings.Count,
                DueSoon = activeBorrowings.Count(b => (b.DueDate - DateTime.UtcNow).Days <= 3 && b.DueDate >= DateTime.UtcNow),
                OverdueCount = activeBorrowings.Count(b => b.DueDate < DateTime.UtcNow),
                OutstandingFines = outstandingFines,
                ActiveReservations = reservations.Count,
                ActiveBorrowings = activeBorrowings.Select(b => new BorrowingItemViewModel
                {
                    BorrowingId = b.BorrowingId,
                    BookTitle = b.BookCopy?.Book?.Title ?? "Unknown",
                    Author = b.BookCopy?.Book?.Author?.Name ?? "Unknown",
                    AccessionNumber = b.BookCopy?.AccessionNumber ?? "",
                    IssueDate = b.IssueDate,
                    DueDate = b.DueDate,
                    RenewalCount = b.RenewalCount
                }).ToList(),
                Alerts = alerts
            };
            return View(model);
        }

        public async Task<IActionResult> MyBorrowings(int page = 1)
        {
            var userId = _userManager.GetUserId(User)!;
            var (borrowings, total) = await _borrowingService.GetBorrowingsAsync(userId: userId, page: page);
            ViewBag.CurrentPage = page;
            ViewBag.TotalPages = (int)Math.Ceiling(total / 10.0);
            return View(borrowings);
        }

        public async Task<IActionResult> MyFines()
        {
            var userId = _userManager.GetUserId(User)!;
            var (fines, _) = await _fineService.GetFinesAsync(userId: userId, pageSize: 50);
            return View(fines);
        }

        public async Task<IActionResult> MyReservations()
        {
            var userId = _userManager.GetUserId(User)!;
            var reservations = await _reservationService.GetUserReservationsAsync(userId);
            return View(reservations);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> CancelReservation(int id)
        {
            var userId = _userManager.GetUserId(User)!;
            var result = await _reservationService.CancelReservationAsync(id, userId);
            TempData[result.Success ? "Success" : "Error"] = result.Message;
            return RedirectToAction("MyReservations");
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> RequestRenewal(int id)
        {
            var borrowing = await _borrowingService.GetByIdAsync(id);
            if (borrowing == null || borrowing.UserId != _userManager.GetUserId(User))
                return Forbid();

            var result = await _borrowingService.RenewBookAsync(id,
                HttpContext.Connection.RemoteIpAddress?.ToString());
            TempData[result.Success ? "Success" : "Error"] = result.Message;
            return RedirectToAction("MyBorrowings");
        }
    }
}
