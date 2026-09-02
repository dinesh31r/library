using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LibraryManagementSystem.Data;
using LibraryManagementSystem.Models;

namespace LibraryManagementSystem.Controllers
{
    [Authorize(Roles = "Admin,Librarian")]
    public class AuthorsController : Controller
    {
        private readonly ApplicationDbContext _context;

        public AuthorsController(ApplicationDbContext context) { _context = context; }

        public async Task<IActionResult> Index(string? searchTerm)
        {
            var query = _context.Authors.AsQueryable();
            if (!string.IsNullOrWhiteSpace(searchTerm))
                query = query.Where(a => a.Name.Contains(searchTerm));
            ViewBag.SearchTerm = searchTerm;
            return View(await query.OrderBy(a => a.Name).ToListAsync());
        }

        [HttpGet] public IActionResult Create() => View();

        [HttpPost, ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(Author model)
        {
            if (!ModelState.IsValid) return View(model);
            model.CreatedAt = DateTime.UtcNow;
            _context.Authors.Add(model);
            await _context.SaveChangesAsync();
            TempData["Success"] = "Author created.";
            return RedirectToAction("Index");
        }

        [HttpGet]
        public async Task<IActionResult> Edit(int id)
        {
            var author = await _context.Authors.FindAsync(id);
            return author == null ? NotFound() : View(author);
        }

        [HttpPost, ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(Author model)
        {
            if (!ModelState.IsValid) return View(model);
            _context.Authors.Update(model);
            await _context.SaveChangesAsync();
            TempData["Success"] = "Author updated.";
            return RedirectToAction("Index");
        }
    }
}
