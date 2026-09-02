using LibraryManagementSystem.Data;
using LibraryManagementSystem.Models;
using Microsoft.EntityFrameworkCore;

namespace LibraryManagementSystem.Services
{
    public class AuditService : IAuditService
    {
        private readonly ApplicationDbContext _context;

        public AuditService(ApplicationDbContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Creates an audit log entry for a significant system action.
        /// </summary>
        public async Task LogAsync(string? userId, string action, string? entityName = null,
            string? entityId = null, string? description = null, string? ipAddress = null)
        {
            var log = new AuditLog
            {
                UserId = userId,
                Action = action,
                EntityName = entityName,
                EntityId = entityId,
                Description = description,
                IPAddress = ipAddress,
                CreatedAt = DateTime.UtcNow
            };
            _context.AuditLogs.Add(log);
            await _context.SaveChangesAsync();
        }

        /// <summary>
        /// Retrieves paginated audit logs with optional filtering.
        /// </summary>
        public async Task<(List<AuditLog> Logs, int TotalCount)> GetLogsAsync(
            string? searchTerm = null, string? action = null,
            DateTime? fromDate = null, DateTime? toDate = null,
            int page = 1, int pageSize = 20)
        {
            var query = _context.AuditLogs
                .Include(a => a.User)
                .AsQueryable();

            if (!string.IsNullOrEmpty(searchTerm))
            {
                query = query.Where(a =>
                    (a.Description != null && a.Description.Contains(searchTerm)) ||
                    (a.EntityName != null && a.EntityName.Contains(searchTerm)) ||
                    (a.User != null && a.User.FullName.Contains(searchTerm)));
            }

            if (!string.IsNullOrEmpty(action))
                query = query.Where(a => a.Action == action);

            if (fromDate.HasValue)
                query = query.Where(a => a.CreatedAt >= fromDate.Value);

            if (toDate.HasValue)
                query = query.Where(a => a.CreatedAt <= toDate.Value.AddDays(1));

            var totalCount = await query.CountAsync();
            var logs = await query
                .OrderByDescending(a => a.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return (logs, totalCount);
        }
    }
}
