using Microsoft.AspNetCore.Mvc;

namespace LibraryManagementSystem.Controllers
{
    public class HomeController : Controller
    {
        public IActionResult Index()
        {
            if (User.Identity?.IsAuthenticated == true)
            {
                if (User.IsInRole("Admin")) return RedirectToAction("Dashboard", "Admin");
                if (User.IsInRole("Librarian")) return RedirectToAction("Dashboard", "Librarian");
                return RedirectToAction("Dashboard", "User");
            }
            return RedirectToAction("Login", "Account");
        }

        [Route("Home/Error")]
        public IActionResult Error(int? statusCode)
        {
            ViewBag.StatusCode = statusCode ?? 500;
            ViewBag.Message = statusCode switch
            {
                403 => "You do not have permission to access this page.",
                404 => "The page you're looking for could not be found.",
                _ => "An unexpected error occurred. Please try again later."
            };
            return View("Error");
        }
    }
}
