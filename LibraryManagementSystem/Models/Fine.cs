using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LibraryManagementSystem.Models
{
    public class Fine
    {
        [Key]
        public int FineId { get; set; }

        [Required]
        public string UserId { get; set; } = string.Empty;

        [Required]
        [Display(Name = "Borrowing")]
        public int BorrowingId { get; set; }

        [Required]
        [Column(TypeName = "decimal(10,2)")]
        [Range(0, 100000)]
        public decimal Amount { get; set; }

        [Required]
        [StringLength(300)]
        public string Reason { get; set; } = string.Empty;

        [Required]
        [Display(Name = "Issued Date")]
        public DateTime IssuedDate { get; set; } = DateTime.UtcNow;

        [Display(Name = "Paid Date")]
        public DateTime? PaidDate { get; set; }

        [Required]
        public FineStatus Status { get; set; } = FineStatus.Pending;

        [StringLength(50)]
        [Display(Name = "Payment Method")]
        public string? PaymentMethod { get; set; }

        [StringLength(500)]
        public string? Notes { get; set; }

        // Navigation
        [ForeignKey("UserId")]
        public virtual ApplicationUser? User { get; set; }

        [ForeignKey("BorrowingId")]
        public virtual Borrowing? Borrowing { get; set; }
    }
}
