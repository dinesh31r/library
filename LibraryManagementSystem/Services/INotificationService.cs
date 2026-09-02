using LibraryManagementSystem.Models;

namespace LibraryManagementSystem.Services
{
    public interface INotificationService
    {
        Task CreateAsync(string userId, string title, string message,
            NotificationType type, string? relatedEntityId = null, string? relatedEntityType = null);
        Task<List<Notification>> GetUserNotificationsAsync(string userId, int count = 20);
        Task<int> GetUnreadCountAsync(string userId);
        Task MarkAsReadAsync(int notificationId, string userId);
        Task MarkAllAsReadAsync(string userId);
    }
}
