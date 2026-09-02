using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LibraryManagementSystem.Models
{
    public class LibrarySetting
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [Display(Name = "Max Books Per User")]
        [Range(1, 50)]
        public int MaxBooksPerUser { get; set; } = 5;

        [Required]
        [Display(Name = "Default Borrowing Period (Days)")]
        [Range(1, 90)]
        public int DefaultBorrowingDays { get; set; } = 14;

        [Required]
        [Display(Name = "Maximum Renewals")]
        [Range(0, 10)]
        public int MaxRenewals { get; set; } = 2;

        [Required]
        [Column(TypeName = "decimal(10,2)")]
        [Display(Name = "Fine Per Overdue Day (₹)")]
        [Range(0, 1000)]
        public decimal FinePerDay { get; set; } = 5.00m;

        [Required]
        [Display(Name = "Reservation Expiry (Days)")]
        [Range(1, 30)]
        public int ReservationExpiryDays { get; set; } = 2;

        [Required]
        [StringLength(200)]
        [Display(Name = "Library Name")]
        public string LibraryName { get; set; } = "Library Management System";

        [StringLength(100)]
        [EmailAddress]
        [Display(Name = "Library Email")]
        public string? LibraryEmail { get; set; }

        [StringLength(20)]
        [Phone]
        [Display(Name = "Library Phone")]
        public string? LibraryPhone { get; set; }

        [StringLength(300)]
        [Display(Name = "Library Address")]
        public string? LibraryAddress { get; set; }

        [Display(Name = "Block Issue On Overdue")]
        public bool BlockIssueOnOverdue { get; set; } = true;

        [Display(Name = "Block Issue On Fine")]
        public bool BlockIssueOnFine { get; set; } = false;
    }
}
