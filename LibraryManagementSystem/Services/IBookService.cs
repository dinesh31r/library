using LibraryManagementSystem.Models;

namespace LibraryManagementSystem.Services
{
    public interface IBookService
    {
        Task<(List<Book> Books, int TotalCount)> SearchBooksAsync(
            string? searchTerm = null, int? categoryId = null, int? authorId = null,
            int? publisherId = null, bool? availableOnly = null, bool? activeOnly = true,
            int page = 1, int pageSize = 10);
        Task<Book?> GetByIdAsync(int bookId);
        Task<Book?> GetByIsbnAsync(string isbn);
        Task<Book> CreateAsync(Book book);
        Task UpdateAsync(Book book);
        Task<bool> ToggleActiveAsync(int bookId);
        Task<List<BookCopy>> GetCopiesAsync(int bookId);
        Task<BookCopy?> GetCopyByIdAsync(int copyId);
        Task<BookCopy?> GetCopyByBarcodeAsync(string barcode);
        Task<BookCopy?> GetCopyByAccessionAsync(string accessionNumber);
        Task<BookCopy> AddCopyAsync(BookCopy copy);
        Task UpdateCopyAsync(BookCopy copy);
        Task<bool> IsIsbnUniqueAsync(string isbn, int? excludeBookId = null);
        Task<List<Book>> GetMostBorrowedAsync(int count = 10);
        Task<Dictionary<string, int>> GetBooksByCategoryAsync();
    }
}
