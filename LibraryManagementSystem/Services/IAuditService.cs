using LibraryManagementSystem.Models;

namespace LibraryManagementSystem.Services
{
    public interface IAuditService
    {
        Task LogAsync(string? userId, string action, string? entityName = null,
            string? entityId = null, string? description = null, string? ipAddress = null);
        Task<(List<AuditLog> Logs, int TotalCount)> GetLogsAsync(
            string? searchTerm = null, string? action = null,
            DateTime? fromDate = null, DateTime? toDate = null,
            int page = 1, int pageSize = 20);
    }
}
