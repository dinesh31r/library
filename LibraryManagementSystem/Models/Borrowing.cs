using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LibraryManagementSystem.Models
{
    public class Borrowing
    {
        [Key]
        public int BorrowingId { get; set; }

        [Required]
        public string UserId { get; set; } = string.Empty;

        [Required]
        [Display(Name = "Book Copy")]
        public int BookCopyId { get; set; }

        [Required]
        [Display(Name = "Issued By")]
        public string IssuedBy { get; set; } = string.Empty;

        [Required]
        [Display(Name = "Issue Date")]
        [DataType(DataType.Date)]
        public DateTime IssueDate { get; set; } = DateTime.UtcNow;

        [Required]
        [Display(Name = "Due Date")]
        [DataType(DataType.Date)]
        public DateTime DueDate { get; set; }

        [Display(Name = "Return Date")]
        [DataType(DataType.Date)]
        public DateTime? ReturnDate { get; set; }

        [Display(Name = "Returned To")]
        public string? ReturnedTo { get; set; }

        [Required]
        public BorrowingStatus Status { get; set; } = BorrowingStatus.Issued;

        [Display(Name = "Renewal Count")]
        [Range(0, 10)]
        public int RenewalCount { get; set; } = 0;

        [Column(TypeName = "decimal(10,2)")]
        [Display(Name = "Fine Amount")]
        public decimal FineAmount { get; set; } = 0;

        [StringLength(500)]
        public string? Notes { get; set; }

        // Navigation
        [ForeignKey("UserId")]
        public virtual ApplicationUser? User { get; set; }

        [ForeignKey("BookCopyId")]
        public virtual BookCopy? BookCopy { get; set; }

        [ForeignKey("IssuedBy")]
        public virtual ApplicationUser? IssuedByUser { get; set; }

        [ForeignKey("ReturnedTo")]
        public virtual ApplicationUser? ReturnedToUser { get; set; }

        public virtual Fine? Fine { get; set; }
    }
}
