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
    [Authorize(Roles = "Admin")]
    public class AdminController : Controller
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly RoleManager<IdentityRole> _roleManager;
        private readonly IBookService _bookService;
        private readonly IBorrowingService _borrowingService;
        private readonly IFineService _fineService;
        private readonly IReservationService _reservationService;
        private readonly IAuditService _auditService;
        private readonly ILibrarySettingsService _settingsService;

        public AdminController(ApplicationDbContext context, UserManager<ApplicationUser> userManager,
            RoleManager<IdentityRole> roleManager, IBookService bookService,
            IBorrowingService borrowingService, IFineService fineService,
            IReservationService reservationService, IAuditService auditService,
            ILibrarySettingsService settingsService)
        {
            _context = context;
            _userManager = userManager;
            _roleManager = roleManager;
            _bookService = bookService;
            _borrowingService = borrowingService;
            _fineService = fineService;
            _reservationService = reservationService;
            _auditService = auditService;
            _settingsService = settingsService;
        }

        public async Task<IActionResult> Dashboard()
        {
            var model = new AdminDashboardViewModel
            {
                TotalBooks = await _context.Books.CountAsync(b => b.IsActive),
                TotalCopies = await _context.BookCopies.CountAsync(),
                AvailableCopies = await _context.BookCopies.CountAsync(c => c.Status == BookCopyStatus.Available),
                IssuedBooks = await _context.Borrowings.CountAsync(b => b.Status == BorrowingStatus.Issued),
                OverdueBooks = await _context.Borrowings.CountAsync(b => b.Status == BorrowingStatus.Issued && b.DueDate < DateTime.UtcNow),
                TotalUsers = (await _userManager.GetUsersInRoleAsync("User")).Count,
                TotalLibrarians = (await _userManager.GetUsersInRoleAsync("Librarian")).Count,
                PendingReservations = await _reservationService.GetPendingCountAsync(),
                OutstandingFines = await _fineService.GetTotalPendingAsync(),
                MonthlyIssued = await _borrowingService.GetMonthlyIssuedAsync(6),
                MonthlyReturned = await _borrowingService.GetMonthlyReturnedAsync(6),
                BooksByCategory = await _bookService.GetBooksByCategoryAsync()
            };

            var mostBorrowed = await _context.Borrowings
                .Include(b => b.BookCopy).ThenInclude(c => c!.Book).ThenInclude(bk => bk!.Author)
                .GroupBy(b => b.BookCopy!.BookId)
                .Select(g => new { BookId = g.Key, Count = g.Count(), First = g.First() })
                .OrderByDescending(x => x.Count)
                .Take(5)
                .ToListAsync();

            model.MostBorrowed = mostBorrowed.Select(x => new MostBorrowedBookViewModel
            {
                Title = x.First.BookCopy?.Book?.Title ?? "Unknown",
                Author = x.First.BookCopy?.Book?.Author?.Name ?? "Unknown",
                BorrowCount = x.Count
            }).ToList();

            return View(model);
        }

        // ── User Management ─────────────────────────────────────────
        public async Task<IActionResult> Users(string? searchTerm, string? roleFilter, int page = 1)
        {
            var users = _userManager.Users.AsQueryable();

            if (!string.IsNullOrWhiteSpace(searchTerm))
            {
                var term = searchTerm.ToLower();
                users = users.Where(u => u.FullName.ToLower().Contains(term) ||
                    u.Email!.ToLower().Contains(term));
            }

            var totalCount = await users.CountAsync();
            var pageSize = 10;
            var userList = await users
                .OrderBy(u => u.FullName)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var items = new List<UserItemViewModel>();
            foreach (var u in userList)
            {
                var roles = await _userManager.GetRolesAsync(u);
                var role = roles.FirstOrDefault() ?? "None";
                if (!string.IsNullOrEmpty(roleFilter) && role != roleFilter) continue;
                items.Add(new UserItemViewModel
                {
                    Id = u.Id, FullName = u.FullName, Email = u.Email!,
                    PhoneNumber = u.PhoneNumber, Role = role,
                    IsActive = u.IsActive, CreatedAt = u.CreatedAt
                });
            }

            var model = new UserListViewModel
            {
                Users = items, SearchTerm = searchTerm, RoleFilter = roleFilter,
                CurrentPage = page, TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
                TotalCount = totalCount
            };
            return View(model);
        }

        [HttpGet]
        public IActionResult CreateUser()
        {
            return View(new UserCreateViewModel());
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> CreateUser(UserCreateViewModel model)
        {
            if (!ModelState.IsValid) return View(model);

            var user = new ApplicationUser
            {
                UserName = model.Email, Email = model.Email, FullName = model.FullName,
                PhoneNumber = model.PhoneNumber, Address = model.Address,
                EmailConfirmed = true, IsActive = true,
                CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow
            };

            var result = await _userManager.CreateAsync(user, model.Password);
            if (result.Succeeded)
            {
                await _userManager.AddToRoleAsync(user, model.Role);
                await _auditService.LogAsync(_userManager.GetUserId(User), "CreateUser", "User", user.Id,
                    $"Created user {user.FullName} with role {model.Role}",
                    HttpContext.Connection.RemoteIpAddress?.ToString());
                TempData["Success"] = "User created successfully.";
                return RedirectToAction("Users");
            }

            foreach (var error in result.Errors)
                ModelState.AddModelError("", error.Description);
            return View(model);
        }

        [HttpGet]
        public async Task<IActionResult> EditUser(string id)
        {
            var user = await _userManager.FindByIdAsync(id);
            if (user == null) return NotFound();

            var roles = await _userManager.GetRolesAsync(user);
            var model = new UserEditViewModel
            {
                Id = user.Id, FullName = user.FullName, Email = user.Email!,
                PhoneNumber = user.PhoneNumber, Address = user.Address,
                Role = roles.FirstOrDefault() ?? "User", IsActive = user.IsActive
            };
            return View(model);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> EditUser(UserEditViewModel model)
        {
            if (!ModelState.IsValid) return View(model);

            var user = await _userManager.FindByIdAsync(model.Id);
            if (user == null) return NotFound();

            user.FullName = model.FullName;
            user.Email = model.Email;
            user.UserName = model.Email;
            user.PhoneNumber = model.PhoneNumber;
            user.Address = model.Address;
            user.IsActive = model.IsActive;
            user.UpdatedAt = DateTime.UtcNow;

            await _userManager.UpdateAsync(user);

            // Update role
            var currentRoles = await _userManager.GetRolesAsync(user);
            await _userManager.RemoveFromRolesAsync(user, currentRoles);
            await _userManager.AddToRoleAsync(user, model.Role);

            await _auditService.LogAsync(_userManager.GetUserId(User), "EditUser", "User", user.Id,
                $"Updated user {user.FullName}", HttpContext.Connection.RemoteIpAddress?.ToString());
            TempData["Success"] = "User updated successfully.";
            return RedirectToAction("Users");
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ToggleUserStatus(string id)
        {
            var user = await _userManager.FindByIdAsync(id);
            if (user == null) return NotFound();
            user.IsActive = !user.IsActive;
            user.UpdatedAt = DateTime.UtcNow;
            await _userManager.UpdateAsync(user);
            TempData["Success"] = $"User {(user.IsActive ? "activated" : "deactivated")} successfully.";
            return RedirectToAction("Users");
        }

        // ── Audit Logs ──────────────────────────────────────────────
        public async Task<IActionResult> AuditLogs(string? searchTerm, string? action, DateTime? fromDate, DateTime? toDate, int page = 1)
        {
            var (logs, total) = await _auditService.GetLogsAsync(searchTerm, action, fromDate, toDate, page, 20);
            ViewBag.SearchTerm = searchTerm;
            ViewBag.Action = action;
            ViewBag.FromDate = fromDate;
            ViewBag.ToDate = toDate;
            ViewBag.CurrentPage = page;
            ViewBag.TotalPages = (int)Math.Ceiling(total / 20.0);
            ViewBag.TotalCount = total;
            return View(logs);
        }

        // ── Settings ────────────────────────────────────────────────
        [HttpGet]
        public async Task<IActionResult> Settings()
        {
            var settings = await _settingsService.GetSettingsAsync();
            return View(settings);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Settings(LibrarySetting model)
        {
            if (!ModelState.IsValid) return View(model);
            await _settingsService.UpdateSettingsAsync(model);
            await _auditService.LogAsync(_userManager.GetUserId(User), "UpdateSettings", "LibrarySetting", "1",
                "Library settings updated", HttpContext.Connection.RemoteIpAddress?.ToString());
            TempData["Success"] = "Settings updated successfully.";
            return View(model);
        }
    }
}
