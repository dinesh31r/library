using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LibraryManagementSystem.Data;
using LibraryManagementSystem.Models;

namespace LibraryManagementSystem.Controllers
{
    [Authorize(Roles = "Admin,Librarian")]
    public class PublishersController : Controller
    {
        private readonly ApplicationDbContext _context;

        public PublishersController(ApplicationDbContext context) { _context = context; }

        public async Task<IActionResult> Index() =>
            View(await _context.Publishers.OrderBy(p => p.Name).ToListAsync());

        [HttpGet] public IActionResult Create() => View();

        [HttpPost, ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(Publisher model)
        {
            if (!ModelState.IsValid) return View(model);
            _context.Publishers.Add(model);
            await _context.SaveChangesAsync();
            TempData["Success"] = "Publisher created.";
            return RedirectToAction("Index");
        }

        [HttpGet]
        public async Task<IActionResult> Edit(int id)
        {
            var pub = await _context.Publishers.FindAsync(id);
            return pub == null ? NotFound() : View(pub);
        }

        [HttpPost, ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(Publisher model)
        {
            if (!ModelState.IsValid) return View(model);
            _context.Publishers.Update(model);
            await _context.SaveChangesAsync();
            TempData["Success"] = "Publisher updated.";
            return RedirectToAction("Index");
        }
    }
}
