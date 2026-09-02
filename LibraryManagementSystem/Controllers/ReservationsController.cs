using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using LibraryManagementSystem.Models;
using LibraryManagementSystem.Services;

namespace LibraryManagementSystem.Controllers
{
    [Authorize(Roles = "Admin,Librarian")]
    public class ReservationsController : Controller
    {
        private readonly IReservationService _reservationService;

        public ReservationsController(IReservationService reservationService)
        {
            _reservationService = reservationService;
        }

        public async Task<IActionResult> Index(string? status, int page = 1)
        {
            ReservationStatus? statusFilter = null;
            if (Enum.TryParse<ReservationStatus>(status, out var s)) statusFilter = s;

            var (reservations, total) = await _reservationService.GetReservationsAsync(status: statusFilter, page: page);
            ViewBag.Status = status;
            ViewBag.CurrentPage = page;
            ViewBag.TotalPages = (int)Math.Ceiling(total / 10.0);
            return View(reservations);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Fulfill(int id)
        {
            var reservation = await _reservationService.GetByIdAsync(id);
            if (reservation != null)
            {
                reservation.Status = ReservationStatus.Fulfilled;
                // Save handled by service layer
            }
            TempData["Success"] = "Reservation fulfilled.";
            return RedirectToAction("Index");
        }
    }
}
