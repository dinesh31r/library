using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using LibraryManagementSystem.Models;
using LibraryManagementSystem.Services;

namespace LibraryManagementSystem.Controllers
{
    [Authorize(Roles = "Admin,Librarian")]
    public class FinesController : Controller
    {
        private readonly IFineService _fineService;
        private readonly UserManager<ApplicationUser> _userManager;

        public FinesController(IFineService fineService, UserManager<ApplicationUser> userManager)
        {
            _fineService = fineService;
            _userManager = userManager;
        }

        public async Task<IActionResult> Index(string? status, int page = 1)
        {
            FineStatus? statusFilter = null;
            if (Enum.TryParse<FineStatus>(status, out var s)) statusFilter = s;

            var (fines, total) = await _fineService.GetFinesAsync(status: statusFilter, page: page);
            ViewBag.Status = status;
            ViewBag.CurrentPage = page;
            ViewBag.TotalPages = (int)Math.Ceiling(total / 10.0);
            return View(fines);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> RecordPayment(int fineId, string paymentMethod, string? notes)
        {
            var result = await _fineService.RecordPaymentAsync(fineId, paymentMethod, notes,
                HttpContext.Connection.RemoteIpAddress?.ToString());
            TempData[result ? "Success" : "Error"] = result ? "Payment recorded." : "Failed to record payment.";
            return RedirectToAction("Index");
        }

        [Authorize(Roles = "Admin")]
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Waive(int fineId, string? notes)
        {
            var result = await _fineService.WaiveFineAsync(fineId, notes,
                HttpContext.Connection.RemoteIpAddress?.ToString());
            TempData[result ? "Success" : "Error"] = result ? "Fine waived." : "Failed to waive fine.";
            return RedirectToAction("Index");
        }
    }
}
