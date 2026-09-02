using LibraryManagementSystem.Models;

namespace LibraryManagementSystem.Services
{
    public class BorrowingResult
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public Borrowing? Borrowing { get; set; }
    }

    public interface IBorrowingService
    {
        Task<BorrowingResult> IssueBookAsync(string userId, int bookCopyId, string issuedByUserId, string? ipAddress = null);
        Task<BorrowingResult> ReturnBookAsync(int borrowingId, string returnedByUserId, string? notes = null, string? ipAddress = null);
        Task<BorrowingResult> RenewBookAsync(int borrowingId, string? ipAddress = null);
        Task<Borrowing?> GetByIdAsync(int borrowingId);
        Task<Borrowing?> GetActiveBorrowingByCopyIdAsync(int bookCopyId);
        Task<(List<Borrowing> Borrowings, int TotalCount)> GetBorrowingsAsync(
            string? userId = null, BorrowingStatus? status = null,
            string? searchTerm = null, DateTime? fromDate = null, DateTime? toDate = null,
            int page = 1, int pageSize = 10);
        Task<List<Borrowing>> GetOverdueBorrowingsAsync();
        Task<List<Borrowing>> GetUserActiveBorrowingsAsync(string userId);
        Task<int> GetUserActiveBorrowingCountAsync(string userId);
        Task<Dictionary<string, int>> GetMonthlyIssuedAsync(int months = 12);
        Task<Dictionary<string, int>> GetMonthlyReturnedAsync(int months = 12);
        Task<int> GetTodayIssueCountAsync();
        Task<int> GetTodayReturnCountAsync();
    }
}
