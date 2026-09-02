using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LibraryManagementSystem.Data;
using LibraryManagementSystem.Models;

namespace LibraryManagementSystem.Controllers
{
    [Authorize(Roles = "Admin,Librarian")]
    public class CategoriesController : Controller
    {
        private readonly ApplicationDbContext _context;

        public CategoriesController(ApplicationDbContext context) { _context = context; }

        public async Task<IActionResult> Index() =>
            View(await _context.Categories.OrderBy(c => c.Name).ToListAsync());

        [HttpGet] public IActionResult Create() => View();

        [HttpPost, ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(Category model)
        {
            if (await _context.Categories.AnyAsync(c => c.Name == model.Name))
                ModelState.AddModelError("Name", "Category name already exists.");
            if (!ModelState.IsValid) return View(model);
            model.CreatedAt = DateTime.UtcNow;
            _context.Categories.Add(model);
            await _context.SaveChangesAsync();
            TempData["Success"] = "Category created.";
            return RedirectToAction("Index");
        }

        [HttpGet]
        public async Task<IActionResult> Edit(int id)
        {
            var cat = await _context.Categories.FindAsync(id);
            return cat == null ? NotFound() : View(cat);
        }

        [HttpPost, ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(Category model)
        {
            if (await _context.Categories.AnyAsync(c => c.Name == model.Name && c.CategoryId != model.CategoryId))
                ModelState.AddModelError("Name", "Category name already exists.");
            if (!ModelState.IsValid) return View(model);
            _context.Categories.Update(model);
            await _context.SaveChangesAsync();
            TempData["Success"] = "Category updated.";
            return RedirectToAction("Index");
        }
    }
}
