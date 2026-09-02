using LibraryManagementSystem.Models;

namespace LibraryManagementSystem.Services
{
    public class ReservationResult
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public Reservation? Reservation { get; set; }
    }

    public interface IReservationService
    {
        Task<ReservationResult> CreateReservationAsync(string userId, int bookId);
        Task<ReservationResult> CancelReservationAsync(int reservationId, string userId);
        Task<Reservation?> GetByIdAsync(int reservationId);
        Task<(List<Reservation> Reservations, int TotalCount)> GetReservationsAsync(
            string? userId = null, ReservationStatus? status = null,
            int page = 1, int pageSize = 10);
        Task<List<Reservation>> GetUserReservationsAsync(string userId);
        Task ExpireOldReservationsAsync();
        Task<int> GetPendingCountAsync();
    }
}
