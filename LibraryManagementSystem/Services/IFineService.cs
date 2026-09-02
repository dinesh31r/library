using LibraryManagementSystem.Models;

namespace LibraryManagementSystem.Services
{
    public interface IFineService
    {
        Task<Fine?> GetByIdAsync(int fineId);
        Task<(List<Fine> Fines, int TotalCount)> GetFinesAsync(
            string? userId = null, FineStatus? status = null,
            DateTime? fromDate = null, DateTime? toDate = null,
            int page = 1, int pageSize = 10);
        Task<decimal> GetUserOutstandingFinesAsync(string userId);
        Task<bool> RecordPaymentAsync(int fineId, string paymentMethod, string? notes = null, string? ipAddress = null);
        Task<bool> WaiveFineAsync(int fineId, string? notes = null, string? ipAddress = null);
        Task<decimal> GetTotalCollectedAsync(DateTime? fromDate = null, DateTime? toDate = null);
        Task<decimal> GetTotalPendingAsync();
    }
}
