using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LibraryManagementSystem.Models
{
    public class Notification
    {
        [Key]
        public int NotificationId { get; set; }

        [Required]
        public string UserId { get; set; } = string.Empty;

        [Required]
        [StringLength(200)]
        public string Title { get; set; } = string.Empty;

        [Required]
        [StringLength(1000)]
        public string Message { get; set; } = string.Empty;

        [Required]
        public NotificationType Type { get; set; } = NotificationType.General;

        [Display(Name = "Read")]
        public bool IsRead { get; set; } = false;

        [StringLength(50)]
        [Display(Name = "Related Entity ID")]
        public string? RelatedEntityId { get; set; }

        [StringLength(50)]
        [Display(Name = "Related Entity Type")]
        public string? RelatedEntityType { get; set; }

        [Required]
        [Display(Name = "Created At")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigation
        [ForeignKey("UserId")]
        public virtual ApplicationUser? User { get; set; }
    }
}
