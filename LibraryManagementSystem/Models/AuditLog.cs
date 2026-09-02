using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LibraryManagementSystem.Models
{
    public class AuditLog
    {
        [Key]
        public int AuditLogId { get; set; }

        public string? UserId { get; set; }

        [Required]
        [StringLength(100)]
        public string Action { get; set; } = string.Empty;

        [StringLength(100)]
        [Display(Name = "Entity Name")]
        public string? EntityName { get; set; }

        [StringLength(50)]
        [Display(Name = "Entity ID")]
        public string? EntityId { get; set; }

        [StringLength(1000)]
        public string? Description { get; set; }

        [StringLength(50)]
        [Display(Name = "IP Address")]
        public string? IPAddress { get; set; }

        [Required]
        [Display(Name = "Created At")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigation
        [ForeignKey("UserId")]
        public virtual ApplicationUser? User { get; set; }
    }
}
