using LibraryManagementSystem.Data;
using LibraryManagementSystem.Models;
using Microsoft.EntityFrameworkCore;

namespace LibraryManagementSystem.Services
{
    public class BorrowingService : IBorrowingService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILibrarySettingsService _settingsService;
        private readonly INotificationService _notificationService;
        private readonly IAuditService _auditService;

        public BorrowingService(ApplicationDbContext context, ILibrarySettingsService settingsService,
            INotificationService notificationService, IAuditService auditService)
        {
            _context = context;
            _settingsService = settingsService;
            _notificationService = notificationService;
            _auditService = auditService;
        }

        public async Task<BorrowingResult> IssueBookAsync(string userId, int bookCopyId, string issuedByUserId, string? ipAddress = null)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var settings = await _settingsService.GetSettingsAsync();
                var user = await _context.Users.FindAsync(userId);
                if (user == null || !user.IsActive)
                    return new BorrowingResult { Message = "User not found or inactive." };

                var copy = await _context.BookCopies.Include(c => c.Book).FirstOrDefaultAsync(c => c.BookCopyId == bookCopyId);
                if (copy == null)
                    return new BorrowingResult { Message = "Book copy not found." };
                if (copy.Status != BookCopyStatus.Available)
                    return new BorrowingResult { Message = $"Book copy is not available. Current status: {copy.Status}." };
                if (copy.Book == null || !copy.Book.IsActive)
                    return new BorrowingResult { Message = "Book is inactive." };

                var activeCount = await GetUserActiveBorrowingCountAsync(userId);
                if (activeCount >= settings.MaxBooksPerUser)
                    return new BorrowingResult { Message = $"User has reached the maximum borrowing limit ({settings.MaxBooksPerUser})." };

                var alreadyHas = await _context.Borrowings.AnyAsync(b => b.UserId == userId && b.BookCopyId == bookCopyId && b.Status == BorrowingStatus.Issued);
                if (alreadyHas)
                    return new BorrowingResult { Message = "User already has this copy issued." };

                if (settings.BlockIssueOnOverdue)
                {
                    var hasOverdue = await _context.Borrowings.AnyAsync(b => b.UserId == userId && b.Status == BorrowingStatus.Issued && b.DueDate < DateTime.UtcNow);
                    if (hasOverdue)
                        return new BorrowingResult { Message = "User has overdue books. Please return them first." };
                }

                if (settings.BlockIssueOnFine)
                {
                    var hasFine = await _context.Fines.AnyAsync(f => f.UserId == userId && f.Status == FineStatus.Pending);
                    if (hasFine)
                        return new BorrowingResult { Message = "User has outstanding fines. Please clear them first." };
                }

                var borrowing = new Borrowing
                {
                    UserId = userId,
                    BookCopyId = bookCopyId,
                    IssuedBy = issuedByUserId,
                    IssueDate = DateTime.UtcNow,
                    DueDate = DateTime.UtcNow.AddDays(settings.DefaultBorrowingDays),
                    Status = BorrowingStatus.Issued
                };
                _context.Borrowings.Add(borrowing);

                copy.Status = BookCopyStatus.Issued;
                copy.Book!.AvailableCopies = Math.Max(0, copy.Book.AvailableCopies - 1);

                await _context.SaveChangesAsync();
                await _auditService.LogAsync(issuedByUserId, "IssueBook", "Borrowing", borrowing.BorrowingId.ToString(),
                    $"Issued '{copy.Book.Title}' (Copy: {copy.AccessionNumber}) to user {user.FullName}", ipAddress);
                await _notificationService.CreateAsync(userId, "Book Issued",
                    $"'{copy.Book.Title}' has been issued. Due: {borrowing.DueDate:MMM dd, yyyy}.",
                    NotificationType.BookIssued, borrowing.BorrowingId.ToString(), "Borrowing");

                await transaction.CommitAsync();
                return new BorrowingResult { Success = true, Message = "Book issued successfully.", Borrowing = borrowing };
            }
            catch (Exception)
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        public async Task<BorrowingResult> ReturnBookAsync(int borrowingId, string returnedByUserId, string? notes = null, string? ipAddress = null)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var settings = await _settingsService.GetSettingsAsync();
                var borrowing = await _context.Borrowings
                    .Include(b => b.BookCopy).ThenInclude(c => c!.Book)
                    .Include(b => b.User)
                    .FirstOrDefaultAsync(b => b.BorrowingId == borrowingId);

                if (borrowing == null)
                    return new BorrowingResult { Message = "Borrowing record not found." };
                if (borrowing.Status == BorrowingStatus.Returned)
                    return new BorrowingResult { Message = "Book already returned." };

                borrowing.ReturnDate = DateTime.UtcNow;
                borrowing.ReturnedTo = returnedByUserId;
                borrowing.Status = BorrowingStatus.Returned;
                borrowing.Notes = notes;

                // Fine calculation
                if (borrowing.ReturnDate > borrowing.DueDate)
                {
                    var overdueDays = (int)(borrowing.ReturnDate.Value - borrowing.DueDate).TotalDays;
                    var fineAmount = overdueDays * settings.FinePerDay;
                    borrowing.FineAmount = fineAmount;

                    var fine = new Fine
                    {
                        UserId = borrowing.UserId,
                        BorrowingId = borrowing.BorrowingId,
                        Amount = fineAmount,
                        Reason = $"Overdue by {overdueDays} day(s) at ₹{settings.FinePerDay}/day",
                        IssuedDate = DateTime.UtcNow,
                        Status = FineStatus.Pending
                    };
                    _context.Fines.Add(fine);

                    await _notificationService.CreateAsync(borrowing.UserId, "Fine Generated",
                        $"A fine of ₹{fineAmount} has been generated for late return of '{borrowing.BookCopy!.Book!.Title}'.",
                        NotificationType.FineGenerated, fine.FineId.ToString(), "Fine");
                }

                // Update book copy
                borrowing.BookCopy!.Status = BookCopyStatus.Available;
                borrowing.BookCopy.Book!.AvailableCopies++;

                await _context.SaveChangesAsync();

                // Process reservation queue
                var nextReservation = await _context.Reservations
                    .Where(r => r.BookId == borrowing.BookCopy.BookId && r.Status == ReservationStatus.Pending)
                    .OrderBy(r => r.QueuePosition)
                    .FirstOrDefaultAsync();

                if (nextReservation != null)
                {
                    nextReservation.Status = ReservationStatus.Ready;
                    nextReservation.ExpiryDate = DateTime.UtcNow.AddDays(settings.ReservationExpiryDays);
                    await _context.SaveChangesAsync();

                    await _notificationService.CreateAsync(nextReservation.UserId, "Reservation Ready",
                        $"Your reservation for '{borrowing.BookCopy.Book.Title}' is ready. Please collect within {settings.ReservationExpiryDays} days.",
                        NotificationType.ReservationReady, nextReservation.ReservationId.ToString(), "Reservation");
                }

                await _auditService.LogAsync(returnedByUserId, "ReturnBook", "Borrowing", borrowing.BorrowingId.ToString(),
                    $"Returned '{borrowing.BookCopy.Book.Title}' (Copy: {borrowing.BookCopy.AccessionNumber}) from user {borrowing.User?.FullName}", ipAddress);

                await _notificationService.CreateAsync(borrowing.UserId, "Book Returned",
                    $"'{borrowing.BookCopy.Book.Title}' has been returned successfully.",
                    NotificationType.BookIssued);

                await transaction.CommitAsync();
                return new BorrowingResult { Success = true, Message = "Book returned successfully.", Borrowing = borrowing };
            }
            catch (Exception)
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        public async Task<BorrowingResult> RenewBookAsync(int borrowingId, string? ipAddress = null)
        {
            var settings = await _settingsService.GetSettingsAsync();
            var borrowing = await _context.Borrowings
                .Include(b => b.BookCopy).ThenInclude(c => c!.Book)
                .FirstOrDefaultAsync(b => b.BorrowingId == borrowingId);

            if (borrowing == null)
                return new BorrowingResult { Message = "Borrowing not found." };
            if (borrowing.Status != BorrowingStatus.Issued)
                return new BorrowingResult { Message = "Only issued books can be renewed." };
            if (borrowing.RenewalCount >= settings.MaxRenewals)
                return new BorrowingResult { Message = $"Maximum renewals ({settings.MaxRenewals}) reached." };

            var hasReservation = await _context.Reservations.AnyAsync(r =>
                r.BookId == borrowing.BookCopy!.BookId &&
                (r.Status == ReservationStatus.Pending || r.Status == ReservationStatus.Ready));
            if (hasReservation)
                return new BorrowingResult { Message = "Cannot renew — another user has reserved this book." };

            if (borrowing.DueDate < DateTime.UtcNow.AddDays(-7))
                return new BorrowingResult { Message = "Book is excessively overdue. Please return it." };

            borrowing.DueDate = DateTime.UtcNow.AddDays(settings.DefaultBorrowingDays);
            borrowing.RenewalCount++;
            await _context.SaveChangesAsync();

            await _auditService.LogAsync(borrowing.UserId, "RenewBook", "Borrowing", borrowing.BorrowingId.ToString(),
                $"Renewed '{borrowing.BookCopy!.Book!.Title}'. New due date: {borrowing.DueDate:MMM dd, yyyy}", ipAddress);

            return new BorrowingResult { Success = true, Message = $"Book renewed. New due date: {borrowing.DueDate:MMM dd, yyyy}.", Borrowing = borrowing };
        }

        public async Task<Borrowing?> GetByIdAsync(int borrowingId)
        {
            return await _context.Borrowings
                .Include(b => b.User)
                .Include(b => b.BookCopy).ThenInclude(c => c!.Book).ThenInclude(bk => bk!.Author)
                .Include(b => b.IssuedByUser)
                .Include(b => b.Fine)
                .FirstOrDefaultAsync(b => b.BorrowingId == borrowingId);
        }

        public async Task<Borrowing?> GetActiveBorrowingByCopyIdAsync(int bookCopyId)
        {
            return await _context.Borrowings
                .Include(b => b.User)
                .Include(b => b.BookCopy).ThenInclude(c => c!.Book)
                .FirstOrDefaultAsync(b => b.BookCopyId == bookCopyId && b.Status == BorrowingStatus.Issued);
        }

        public async Task<(List<Borrowing> Borrowings, int TotalCount)> GetBorrowingsAsync(
            string? userId = null, BorrowingStatus? status = null,
            string? searchTerm = null, DateTime? fromDate = null, DateTime? toDate = null,
            int page = 1, int pageSize = 10)
        {
            var query = _context.Borrowings
                .Include(b => b.User)
                .Include(b => b.BookCopy).ThenInclude(c => c!.Book).ThenInclude(bk => bk!.Author)
                .Include(b => b.IssuedByUser)
                .AsQueryable();

            if (!string.IsNullOrEmpty(userId))
                query = query.Where(b => b.UserId == userId);
            if (status.HasValue)
                query = query.Where(b => b.Status == status.Value);
            if (fromDate.HasValue)
                query = query.Where(b => b.IssueDate >= fromDate.Value);
            if (toDate.HasValue)
                query = query.Where(b => b.IssueDate <= toDate.Value.AddDays(1));
            if (!string.IsNullOrWhiteSpace(searchTerm))
            {
                var term = searchTerm.ToLower();
                query = query.Where(b =>
                    b.BookCopy!.Book!.Title.ToLower().Contains(term) ||
                    b.User!.FullName.ToLower().Contains(term) ||
                    b.BookCopy.AccessionNumber.ToLower().Contains(term));
            }

            var total = await query.CountAsync();
            var borrowings = await query
                .OrderByDescending(b => b.IssueDate)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return (borrowings, total);
        }

        public async Task<List<Borrowing>> GetOverdueBorrowingsAsync()
        {
            return await _context.Borrowings
                .Include(b => b.User)
                .Include(b => b.BookCopy).ThenInclude(c => c!.Book)
                .Where(b => b.Status == BorrowingStatus.Issued && b.DueDate < DateTime.UtcNow)
                .OrderBy(b => b.DueDate)
                .ToListAsync();
        }

        public async Task<List<Borrowing>> GetUserActiveBorrowingsAsync(string userId)
        {
            return await _context.Borrowings
                .Include(b => b.BookCopy).ThenInclude(c => c!.Book).ThenInclude(bk => bk!.Author)
                .Where(b => b.UserId == userId && b.Status == BorrowingStatus.Issued)
                .OrderBy(b => b.DueDate)
                .ToListAsync();
        }

        public async Task<int> GetUserActiveBorrowingCountAsync(string userId)
        {
            return await _context.Borrowings.CountAsync(b => b.UserId == userId && b.Status == BorrowingStatus.Issued);
        }

        public async Task<Dictionary<string, int>> GetMonthlyIssuedAsync(int months = 12)
        {
            var startDate = DateTime.UtcNow.AddMonths(-months);
            var data = await _context.Borrowings
                .Where(b => b.IssueDate >= startDate)
                .GroupBy(b => new { b.IssueDate.Year, b.IssueDate.Month })
                .Select(g => new { g.Key.Year, g.Key.Month, Count = g.Count() })
                .OrderBy(g => g.Year).ThenBy(g => g.Month)
                .ToListAsync();
            return data.ToDictionary(x => $"{x.Year}-{x.Month:D2}", x => x.Count);
        }

        public async Task<Dictionary<string, int>> GetMonthlyReturnedAsync(int months = 12)
        {
            var startDate = DateTime.UtcNow.AddMonths(-months);
            var data = await _context.Borrowings
                .Where(b => b.ReturnDate.HasValue && b.ReturnDate >= startDate)
                .GroupBy(b => new { b.ReturnDate!.Value.Year, b.ReturnDate!.Value.Month })
                .Select(g => new { g.Key.Year, g.Key.Month, Count = g.Count() })
                .OrderBy(g => g.Year).ThenBy(g => g.Month)
                .ToListAsync();
            return data.ToDictionary(x => $"{x.Year}-{x.Month:D2}", x => x.Count);
        }

        public async Task<int> GetTodayIssueCountAsync()
        {
            var today = DateTime.UtcNow.Date;
            return await _context.Borrowings.CountAsync(b => b.IssueDate.Date == today);
        }

        public async Task<int> GetTodayReturnCountAsync()
        {
            var today = DateTime.UtcNow.Date;
            return await _context.Borrowings.CountAsync(b => b.ReturnDate.HasValue && b.ReturnDate.Value.Date == today);
        }
    }
}
