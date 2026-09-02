using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using LibraryManagementSystem.Models;
using LibraryManagementSystem.Services;
using LibraryManagementSystem.ViewModels;

namespace LibraryManagementSystem.Controllers
{
    [Authorize(Roles = "Admin,Librarian")]
    public class LibrarianController : Controller
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IBorrowingService _borrowingService;
        private readonly IBookService _bookService;
        private readonly IFineService _fineService;
        private readonly IReservationService _reservationService;

        public LibrarianController(UserManager<ApplicationUser> userManager,
            IBorrowingService borrowingService, IBookService bookService,
            IFineService fineService, IReservationService reservationService)
        {
            _userManager = userManager;
            _borrowingService = borrowingService;
            _bookService = bookService;
            _fineService = fineService;
            _reservationService = reservationService;
        }

        public async Task<IActionResult> Dashboard()
        {
            var model = new LibrarianDashboardViewModel
            {
                TotalBooks = (await _bookService.SearchBooksAsync(activeOnly: true, pageSize: 1)).TotalCount,
                AvailableCopies = (await _bookService.SearchBooksAsync(availableOnly: true, pageSize: 1)).TotalCount,
                IssuedBooks = (await _borrowingService.GetBorrowingsAsync(status: BorrowingStatus.Issued, pageSize: 1)).TotalCount,
                TodayIssues = await _borrowingService.GetTodayIssueCountAsync(),
                TodayReturns = await _borrowingService.GetTodayReturnCountAsync(),
                OverdueBooks = (await _borrowingService.GetOverdueBorrowingsAsync()).Count,
                PendingReservations = await _reservationService.GetPendingCountAsync(),
                OutstandingFines = await _fineService.GetTotalPendingAsync()
            };
            return View(model);
        }
    }
}
