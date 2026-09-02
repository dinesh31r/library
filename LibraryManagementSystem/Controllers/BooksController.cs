using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using LibraryManagementSystem.Data;
using LibraryManagementSystem.Models;
using LibraryManagementSystem.Services;
using LibraryManagementSystem.ViewModels;

namespace LibraryManagementSystem.Controllers
{
    [Authorize]
    public class BooksController : Controller
    {
        private readonly IBookService _bookService;
        private readonly IReservationService _reservationService;
        private readonly IAuditService _auditService;
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;

        public BooksController(IBookService bookService, IReservationService reservationService,
            IAuditService auditService, ApplicationDbContext context, UserManager<ApplicationUser> userManager)
        {
            _bookService = bookService;
            _reservationService = reservationService;
            _auditService = auditService;
            _context = context;
            _userManager = userManager;
        }

        public async Task<IActionResult> Index(string? searchTerm, int? categoryId, int? authorId, int? publisherId, bool? availableOnly, int page = 1)
        {
            var (books, total) = await _bookService.SearchBooksAsync(searchTerm, categoryId, authorId, publisherId, availableOnly, true, page, 12);

            var model = new BookListViewModel
            {
                Books = books.Select(b => new BookItemViewModel
                {
                    BookId = b.BookId, ISBN = b.ISBN, Title = b.Title,
                    Author = b.Author?.Name ?? "", Category = b.Category?.Name ?? "",
                    AvailableCopies = b.AvailableCopies, TotalCopies = b.TotalCopies,
                    CoverImage = b.CoverImage, IsActive = b.IsActive
                }).ToList(),
                SearchTerm = searchTerm, CategoryId = categoryId, AuthorId = authorId,
                PublisherId = publisherId, AvailableOnly = availableOnly,
                CurrentPage = page, TotalPages = (int)Math.Ceiling(total / 12.0), TotalCount = total,
                Categories = await GetCategorySelectList(),
                Authors = await GetAuthorSelectList(),
                Publishers = await GetPublisherSelectList()
            };
            return View(model);
        }

        public async Task<IActionResult> Details(int id)
        {
            var book = await _bookService.GetByIdAsync(id);
            if (book == null) return NotFound();

            var userId = _userManager.GetUserId(User);
            var hasReservation = userId != null && await _context.Reservations.AnyAsync(r =>
                r.UserId == userId && r.BookId == id &&
                (r.Status == ReservationStatus.Pending || r.Status == ReservationStatus.Ready));

            var model = new BookDetailViewModel
            {
                BookId = book.BookId, ISBN = book.ISBN, Title = book.Title,
                Description = book.Description, Author = book.Author?.Name ?? "",
                AuthorId = book.AuthorId, Category = book.Category?.Name ?? "",
                Publisher = book.Publisher?.Name ?? "", PublicationYear = book.PublicationYear,
                Edition = book.Edition, Language = book.Language,
                TotalCopies = book.TotalCopies, AvailableCopies = book.AvailableCopies,
                ShelfLocation = book.ShelfLocation, CoverImage = book.CoverImage,
                IsActive = book.IsActive,
                Copies = book.BookCopies.Select(c => new BookCopyItemViewModel
                {
                    BookCopyId = c.BookCopyId, AccessionNumber = c.AccessionNumber,
                    Barcode = c.Barcode, Status = c.Status,
                    Condition = c.Condition, ShelfLocation = c.ShelfLocation
                }).ToList(),
                CanReserve = User.IsInRole("User") && book.AvailableCopies == 0 && !hasReservation,
                HasActiveReservation = hasReservation
            };
            return View(model);
        }

        [Authorize(Roles = "Admin,Librarian")]
        [HttpGet]
        public async Task<IActionResult> Create()
        {
            var model = new BookCreateViewModel
            {
                Authors = await GetAuthorSelectList(),
                Categories = await GetCategorySelectList(),
                Publishers = await GetPublisherSelectList()
            };
            return View(model);
        }

        [Authorize(Roles = "Admin,Librarian")]
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(BookCreateViewModel model)
        {
            if (!await _bookService.IsIsbnUniqueAsync(model.ISBN))
                ModelState.AddModelError("ISBN", "ISBN already exists.");

            if (!ModelState.IsValid)
            {
                model.Authors = await GetAuthorSelectList();
                model.Categories = await GetCategorySelectList();
                model.Publishers = await GetPublisherSelectList();
                return View(model);
            }

            var book = new Book
            {
                ISBN = model.ISBN, Title = model.Title, Description = model.Description,
                AuthorId = model.AuthorId, CategoryId = model.CategoryId,
                PublisherId = model.PublisherId, PublicationYear = model.PublicationYear,
                Edition = model.Edition, Language = model.Language,
                TotalCopies = model.InitialCopies, AvailableCopies = model.InitialCopies,
                ShelfLocation = model.ShelfLocation
            };
            await _bookService.CreateAsync(book);

            // Create initial copies
            for (int i = 0; i < model.InitialCopies; i++)
            {
                var accNum = $"ACC-{book.BookId:D3}-{(i + 1):D3}";
                await _bookService.AddCopyAsync(new BookCopy
                {
                    BookId = book.BookId, AccessionNumber = accNum,
                    Barcode = $"LIB-{book.BookId:D3}-{(i + 1):D3}",
                    Status = BookCopyStatus.Available, Condition = "New",
                    PurchaseDate = DateTime.UtcNow, ShelfLocation = model.ShelfLocation
                });
            }

            // Reset TotalCopies (AddCopyAsync increments it)
            book.TotalCopies = model.InitialCopies;
            book.AvailableCopies = model.InitialCopies;
            await _bookService.UpdateAsync(book);

            await _auditService.LogAsync(_userManager.GetUserId(User), "CreateBook", "Book",
                book.BookId.ToString(), $"Created book '{book.Title}'",
                HttpContext.Connection.RemoteIpAddress?.ToString());
            TempData["Success"] = "Book created successfully.";
            return RedirectToAction("Details", new { id = book.BookId });
        }

        [Authorize(Roles = "Admin,Librarian")]
        [HttpGet]
        public async Task<IActionResult> Edit(int id)
        {
            var book = await _bookService.GetByIdAsync(id);
            if (book == null) return NotFound();

            var model = new BookEditViewModel
            {
                BookId = book.BookId, ISBN = book.ISBN, Title = book.Title,
                Description = book.Description, AuthorId = book.AuthorId,
                CategoryId = book.CategoryId, PublisherId = book.PublisherId,
                PublicationYear = book.PublicationYear, Edition = book.Edition,
                Language = book.Language, ShelfLocation = book.ShelfLocation,
                IsActive = book.IsActive,
                Authors = await GetAuthorSelectList(),
                Categories = await GetCategorySelectList(),
                Publishers = await GetPublisherSelectList()
            };
            return View(model);
        }

        [Authorize(Roles = "Admin,Librarian")]
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(BookEditViewModel model)
        {
            if (!await _bookService.IsIsbnUniqueAsync(model.ISBN, model.BookId))
                ModelState.AddModelError("ISBN", "ISBN already exists.");

            if (!ModelState.IsValid)
            {
                model.Authors = await GetAuthorSelectList();
                model.Categories = await GetCategorySelectList();
                model.Publishers = await GetPublisherSelectList();
                return View(model);
            }

            var book = await _bookService.GetByIdAsync(model.BookId);
            if (book == null) return NotFound();

            book.ISBN = model.ISBN; book.Title = model.Title;
            book.Description = model.Description; book.AuthorId = model.AuthorId;
            book.CategoryId = model.CategoryId; book.PublisherId = model.PublisherId;
            book.PublicationYear = model.PublicationYear; book.Edition = model.Edition;
            book.Language = model.Language; book.ShelfLocation = model.ShelfLocation;
            book.IsActive = model.IsActive;

            await _bookService.UpdateAsync(book);
            await _auditService.LogAsync(_userManager.GetUserId(User), "EditBook", "Book",
                book.BookId.ToString(), $"Updated book '{book.Title}'",
                HttpContext.Connection.RemoteIpAddress?.ToString());
            TempData["Success"] = "Book updated successfully.";
            return RedirectToAction("Details", new { id = book.BookId });
        }

        [Authorize(Roles = "Admin,Librarian")]
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ToggleActive(int id)
        {
            await _bookService.ToggleActiveAsync(id);
            TempData["Success"] = "Book status updated.";
            return RedirectToAction("Index");
        }

        // ── Book Copies ─────────────────────────────────────────────
        [Authorize(Roles = "Admin,Librarian")]
        [HttpGet]
        public async Task<IActionResult> AddCopy(int bookId)
        {
            var book = await _bookService.GetByIdAsync(bookId);
            if (book == null) return NotFound();
            var model = new BookCopyCreateViewModel { BookId = bookId, BookTitle = book.Title };
            return View(model);
        }

        [Authorize(Roles = "Admin,Librarian")]
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> AddCopy(BookCopyCreateViewModel model)
        {
            if (!ModelState.IsValid)
            {
                var b = await _bookService.GetByIdAsync(model.BookId);
                model.BookTitle = b?.Title ?? "";
                return View(model);
            }

            var copy = new BookCopy
            {
                BookId = model.BookId, AccessionNumber = model.AccessionNumber,
                Barcode = model.Barcode, Condition = model.Condition,
                PurchaseDate = model.PurchaseDate, Price = model.Price,
                ShelfLocation = model.ShelfLocation, Status = BookCopyStatus.Available
            };
            await _bookService.AddCopyAsync(copy);
            TempData["Success"] = "Copy added successfully.";
            return RedirectToAction("Details", new { id = model.BookId });
        }

        // ── Reserve ─────────────────────────────────────────────────
        [Authorize(Roles = "User")]
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Reserve(int bookId)
        {
            var userId = _userManager.GetUserId(User)!;
            var result = await _reservationService.CreateReservationAsync(userId, bookId);
            TempData[result.Success ? "Success" : "Error"] = result.Message;
            return RedirectToAction("Details", new { id = bookId });
        }

        // ── AJAX Search ─────────────────────────────────────────────
        [HttpGet]
        public async Task<IActionResult> SearchApi(string? q)
        {
            if (string.IsNullOrWhiteSpace(q)) return Json(new List<object>());
            var (books, _) = await _bookService.SearchBooksAsync(q, pageSize: 10);
            return Json(books.Select(b => new
            {
                b.BookId, b.Title, b.ISBN, Author = b.Author?.Name,
                b.AvailableCopies, b.TotalCopies
            }));
        }

        private async Task<List<SelectListItem>> GetCategorySelectList() =>
            await _context.Categories.Where(c => c.IsActive)
                .OrderBy(c => c.Name)
                .Select(c => new SelectListItem { Value = c.CategoryId.ToString(), Text = c.Name })
                .ToListAsync();

        private async Task<List<SelectListItem>> GetAuthorSelectList() =>
            await _context.Authors.Where(a => a.IsActive)
                .OrderBy(a => a.Name)
                .Select(a => new SelectListItem { Value = a.AuthorId.ToString(), Text = a.Name })
                .ToListAsync();

        private async Task<List<SelectListItem>> GetPublisherSelectList() =>
            await _context.Publishers.Where(p => p.IsActive)
                .OrderBy(p => p.Name)
                .Select(p => new SelectListItem { Value = p.PublisherId.ToString(), Text = p.Name })
                .ToListAsync();
    }
}
