using LibraryManagementSystem.Data;
using LibraryManagementSystem.Models;
using Microsoft.EntityFrameworkCore;

namespace LibraryManagementSystem.Services
{
    public class ReservationService : IReservationService
    {
        private readonly ApplicationDbContext _context;
        private readonly INotificationService _notificationService;
        private readonly ILibrarySettingsService _settingsService;

        public ReservationService(ApplicationDbContext context,
            INotificationService notificationService, ILibrarySettingsService settingsService)
        {
            _context = context;
            _notificationService = notificationService;
            _settingsService = settingsService;
        }

        public async Task<ReservationResult> CreateReservationAsync(string userId, int bookId)
        {
            var book = await _context.Books.FindAsync(bookId);
            if (book == null || !book.IsActive)
                return new ReservationResult { Message = "Book not found or inactive." };

            var existing = await _context.Reservations.AnyAsync(r =>
                r.UserId == userId && r.BookId == bookId &&
                (r.Status == ReservationStatus.Pending || r.Status == ReservationStatus.Ready));
            if (existing)
                return new ReservationResult { Message = "You already have an active reservation for this book." };

            var maxPosition = await _context.Reservations
                .Where(r => r.BookId == bookId && r.Status == ReservationStatus.Pending)
                .MaxAsync(r => (int?)r.QueuePosition) ?? 0;

            var reservation = new Reservation
            {
                UserId = userId,
                BookId = bookId,
                ReservationDate = DateTime.UtcNow,
                Status = ReservationStatus.Pending,
                QueuePosition = maxPosition + 1
            };
            _context.Reservations.Add(reservation);
            await _context.SaveChangesAsync();

            return new ReservationResult
            {
                Success = true,
                Message = $"Reservation created. Queue position: {reservation.QueuePosition}.",
                Reservation = reservation
            };
        }

        public async Task<ReservationResult> CancelReservationAsync(int reservationId, string userId)
        {
            var reservation = await _context.Reservations
                .FirstOrDefaultAsync(r => r.ReservationId == reservationId && r.UserId == userId);
            if (reservation == null)
                return new ReservationResult { Message = "Reservation not found." };
            if (reservation.Status != ReservationStatus.Pending && reservation.Status != ReservationStatus.Ready)
                return new ReservationResult { Message = "Only pending or ready reservations can be cancelled." };

            reservation.Status = ReservationStatus.Cancelled;
            await _context.SaveChangesAsync();

            return new ReservationResult { Success = true, Message = "Reservation cancelled.", Reservation = reservation };
        }

        public async Task<Reservation?> GetByIdAsync(int reservationId)
        {
            return await _context.Reservations
                .Include(r => r.User)
                .Include(r => r.Book).ThenInclude(b => b!.Author)
                .FirstOrDefaultAsync(r => r.ReservationId == reservationId);
        }

        public async Task<(List<Reservation> Reservations, int TotalCount)> GetReservationsAsync(
            string? userId = null, ReservationStatus? status = null,
            int page = 1, int pageSize = 10)
        {
            var query = _context.Reservations
                .Include(r => r.User)
                .Include(r => r.Book).ThenInclude(b => b!.Author)
                .AsQueryable();

            if (!string.IsNullOrEmpty(userId))
                query = query.Where(r => r.UserId == userId);
            if (status.HasValue)
                query = query.Where(r => r.Status == status.Value);

            var total = await query.CountAsync();
            var reservations = await query
                .OrderByDescending(r => r.ReservationDate)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return (reservations, total);
        }

        public async Task<List<Reservation>> GetUserReservationsAsync(string userId)
        {
            return await _context.Reservations
                .Include(r => r.Book).ThenInclude(b => b!.Author)
                .Where(r => r.UserId == userId &&
                    (r.Status == ReservationStatus.Pending || r.Status == ReservationStatus.Ready))
                .OrderBy(r => r.QueuePosition)
                .ToListAsync();
        }

        public async Task ExpireOldReservationsAsync()
        {
            var expired = await _context.Reservations
                .Where(r => r.Status == ReservationStatus.Ready &&
                    r.ExpiryDate.HasValue && r.ExpiryDate < DateTime.UtcNow)
                .ToListAsync();

            foreach (var r in expired)
            {
                r.Status = ReservationStatus.Expired;
                await _notificationService.CreateAsync(r.UserId, "Reservation Expired",
                    "Your reservation has expired as the book was not collected in time.",
                    NotificationType.ReservationExpired, r.ReservationId.ToString(), "Reservation");
            }
            await _context.SaveChangesAsync();
        }

        public async Task<int> GetPendingCountAsync()
        {
            return await _context.Reservations.CountAsync(r =>
                r.Status == ReservationStatus.Pending || r.Status == ReservationStatus.Ready);
        }
    }
}
