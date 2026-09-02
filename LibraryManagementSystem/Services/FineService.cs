using LibraryManagementSystem.Data;
using LibraryManagementSystem.Models;
using Microsoft.EntityFrameworkCore;

namespace LibraryManagementSystem.Services
{
    public class FineService : IFineService
    {
        private readonly ApplicationDbContext _context;
        private readonly IAuditService _auditService;
        private readonly INotificationService _notificationService;

        public FineService(ApplicationDbContext context, IAuditService auditService, INotificationService notificationService)
        {
            _context = context;
            _auditService = auditService;
            _notificationService = notificationService;
        }

        public async Task<Fine?> GetByIdAsync(int fineId)
        {
            return await _context.Fines
                .Include(f => f.User)
                .Include(f => f.Borrowing).ThenInclude(b => b!.BookCopy).ThenInclude(c => c!.Book)
                .FirstOrDefaultAsync(f => f.FineId == fineId);
        }

        public async Task<(List<Fine> Fines, int TotalCount)> GetFinesAsync(
            string? userId = null, FineStatus? status = null,
            DateTime? fromDate = null, DateTime? toDate = null,
            int page = 1, int pageSize = 10)
        {
            var query = _context.Fines
                .Include(f => f.User)
                .Include(f => f.Borrowing).ThenInclude(b => b!.BookCopy).ThenInclude(c => c!.Book)
                .AsQueryable();

            if (!string.IsNullOrEmpty(userId))
                query = query.Where(f => f.UserId == userId);
            if (status.HasValue)
                query = query.Where(f => f.Status == status.Value);
            if (fromDate.HasValue)
                query = query.Where(f => f.IssuedDate >= fromDate.Value);
            if (toDate.HasValue)
                query = query.Where(f => f.IssuedDate <= toDate.Value.AddDays(1));

            var total = await query.CountAsync();
            var fines = await query
                .OrderByDescending(f => f.IssuedDate)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return (fines, total);
        }

        public async Task<decimal> GetUserOutstandingFinesAsync(string userId)
        {
            var amounts = await _context.Fines
                .Where(f => f.UserId == userId && f.Status == FineStatus.Pending)
                .Select(f => f.Amount)
                .ToListAsync();
            return amounts.Sum();
        }

        public async Task<bool> RecordPaymentAsync(int fineId, string paymentMethod, string? notes = null, string? ipAddress = null)
        {
            var fine = await _context.Fines.Include(f => f.User).FirstOrDefaultAsync(f => f.FineId == fineId);
            if (fine == null || fine.Status != FineStatus.Pending) return false;

            fine.Status = FineStatus.Paid;
            fine.PaidDate = DateTime.UtcNow;
            fine.PaymentMethod = paymentMethod;
            fine.Notes = notes;
            await _context.SaveChangesAsync();

            await _auditService.LogAsync(null, "FinePayment", "Fine", fineId.ToString(),
                $"Fine of ₹{fine.Amount} paid by {fine.User?.FullName} via {paymentMethod}", ipAddress);
            await _notificationService.CreateAsync(fine.UserId, "Fine Paid",
                $"Your fine of ₹{fine.Amount} has been recorded as paid.",
                NotificationType.FinePaid, fineId.ToString(), "Fine");

            return true;
        }

        public async Task<bool> WaiveFineAsync(int fineId, string? notes = null, string? ipAddress = null)
        {
            var fine = await _context.Fines.FindAsync(fineId);
            if (fine == null || fine.Status != FineStatus.Pending) return false;

            fine.Status = FineStatus.Waived;
            fine.PaidDate = DateTime.UtcNow;
            fine.Notes = notes ?? "Waived by administrator";
            await _context.SaveChangesAsync();

            await _auditService.LogAsync(null, "FineWaived", "Fine", fineId.ToString(),
                $"Fine of ₹{fine.Amount} waived. Reason: {fine.Notes}", ipAddress);

            return true;
        }

        public async Task<decimal> GetTotalCollectedAsync(DateTime? fromDate = null, DateTime? toDate = null)
        {
            var query = _context.Fines.Where(f => f.Status == FineStatus.Paid);
            if (fromDate.HasValue) query = query.Where(f => f.PaidDate >= fromDate);
            if (toDate.HasValue) query = query.Where(f => f.PaidDate <= toDate.Value.AddDays(1));
            var amounts = await query.Select(f => f.Amount).ToListAsync();
            return amounts.Sum();
        }

        public async Task<decimal> GetTotalPendingAsync()
        {
            var amounts = await _context.Fines
                .Where(f => f.Status == FineStatus.Pending)
                .Select(f => f.Amount)
                .ToListAsync();
            return amounts.Sum();
        }
    }
}
