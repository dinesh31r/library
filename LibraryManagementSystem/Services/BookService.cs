using LibraryManagementSystem.Data;
using LibraryManagementSystem.Models;
using Microsoft.EntityFrameworkCore;

namespace LibraryManagementSystem.Services
{
    public class BookService : IBookService
    {
        private readonly ApplicationDbContext _context;

        public BookService(ApplicationDbContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Searches and filters books with pagination.
        /// </summary>
        public async Task<(List<Book> Books, int TotalCount)> SearchBooksAsync(
            string? searchTerm = null, int? categoryId = null, int? authorId = null,
            int? publisherId = null, bool? availableOnly = null, bool? activeOnly = true,
            int page = 1, int pageSize = 10)
        {
            var query = _context.Books
                .Include(b => b.Author)
                .Include(b => b.Category)
                .Include(b => b.Publisher)
                .AsQueryable();

            if (activeOnly == true)
                query = query.Where(b => b.IsActive);

            if (!string.IsNullOrWhiteSpace(searchTerm))
            {
                var term = searchTerm.Trim().ToLower();
                query = query.Where(b =>
                    b.Title.ToLower().Contains(term) ||
                    b.ISBN.ToLower().Contains(term) ||
                    (b.Author != null && b.Author.Name.ToLower().Contains(term)) ||
                    (b.Description != null && b.Description.ToLower().Contains(term)));
            }

            if (categoryId.HasValue)
                query = query.Where(b => b.CategoryId == categoryId.Value);

            if (authorId.HasValue)
                query = query.Where(b => b.AuthorId == authorId.Value);

            if (publisherId.HasValue)
                query = query.Where(b => b.PublisherId == publisherId.Value);

            if (availableOnly == true)
                query = query.Where(b => b.AvailableCopies > 0);

            var totalCount = await query.CountAsync();
            var books = await query
                .OrderBy(b => b.Title)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return (books, totalCount);
        }

        public async Task<Book?> GetByIdAsync(int bookId)
        {
            return await _context.Books
                .Include(b => b.Author)
                .Include(b => b.Category)
                .Include(b => b.Publisher)
                .Include(b => b.BookCopies)
                .FirstOrDefaultAsync(b => b.BookId == bookId);
        }

        public async Task<Book?> GetByIsbnAsync(string isbn)
        {
            return await _context.Books
                .Include(b => b.Author)
                .FirstOrDefaultAsync(b => b.ISBN == isbn);
        }

        public async Task<Book> CreateAsync(Book book)
        {
            book.CreatedAt = DateTime.UtcNow;
            book.UpdatedAt = DateTime.UtcNow;
            _context.Books.Add(book);
            await _context.SaveChangesAsync();
            return book;
        }

        public async Task UpdateAsync(Book book)
        {
            book.UpdatedAt = DateTime.UtcNow;
            _context.Books.Update(book);
            await _context.SaveChangesAsync();
        }

        public async Task<bool> ToggleActiveAsync(int bookId)
        {
            var book = await _context.Books.FindAsync(bookId);
            if (book == null) return false;
            book.IsActive = !book.IsActive;
            book.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<List<BookCopy>> GetCopiesAsync(int bookId)
        {
            return await _context.BookCopies
                .Where(bc => bc.BookId == bookId)
                .OrderBy(bc => bc.AccessionNumber)
                .ToListAsync();
        }

        public async Task<BookCopy?> GetCopyByIdAsync(int copyId)
        {
            return await _context.BookCopies
                .Include(bc => bc.Book)
                    .ThenInclude(b => b!.Author)
                .FirstOrDefaultAsync(bc => bc.BookCopyId == copyId);
        }

        public async Task<BookCopy?> GetCopyByBarcodeAsync(string barcode)
        {
            return await _context.BookCopies
                .Include(bc => bc.Book)
                    .ThenInclude(b => b!.Author)
                .FirstOrDefaultAsync(bc => bc.Barcode == barcode);
        }

        public async Task<BookCopy?> GetCopyByAccessionAsync(string accessionNumber)
        {
            return await _context.BookCopies
                .Include(bc => bc.Book)
                    .ThenInclude(b => b!.Author)
                .FirstOrDefaultAsync(bc => bc.AccessionNumber == accessionNumber);
        }

        public async Task<BookCopy> AddCopyAsync(BookCopy copy)
        {
            _context.BookCopies.Add(copy);

            var book = await _context.Books.FindAsync(copy.BookId);
            if (book != null)
            {
                book.TotalCopies++;
                if (copy.Status == BookCopyStatus.Available)
                    book.AvailableCopies++;
                book.UpdatedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();
            return copy;
        }

        public async Task UpdateCopyAsync(BookCopy copy)
        {
            _context.BookCopies.Update(copy);
            await _context.SaveChangesAsync();
        }

        public async Task<bool> IsIsbnUniqueAsync(string isbn, int? excludeBookId = null)
        {
            var query = _context.Books.Where(b => b.ISBN == isbn);
            if (excludeBookId.HasValue)
                query = query.Where(b => b.BookId != excludeBookId.Value);
            return !await query.AnyAsync();
        }

        public async Task<List<Book>> GetMostBorrowedAsync(int count = 10)
        {
            return await _context.Books
                .Include(b => b.Author)
                .Include(b => b.Category)
                .OrderByDescending(b => _context.Borrowings
                    .Count(br => br.BookCopy!.BookId == b.BookId))
                .Take(count)
                .ToListAsync();
        }

        public async Task<Dictionary<string, int>> GetBooksByCategoryAsync()
        {
            return await _context.Books
                .Where(b => b.IsActive)
                .GroupBy(b => b.Category!.Name)
                .Select(g => new { Category = g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.Category, x => x.Count);
        }
    }
}
