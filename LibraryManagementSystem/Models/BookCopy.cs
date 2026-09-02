using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LibraryManagementSystem.Models
{
    public class BookCopy
    {
        [Key]
        public int BookCopyId { get; set; }

        [Required]
        [Display(Name = "Book")]
        public int BookId { get; set; }

        [Required]
        [StringLength(50)]
        [Display(Name = "Accession Number")]
        public string AccessionNumber { get; set; } = string.Empty;

        [Required]
        [StringLength(50)]
        public string Barcode { get; set; } = string.Empty;

        [Required]
        public BookCopyStatus Status { get; set; } = BookCopyStatus.Available;

        [StringLength(50)]
        public string? Condition { get; set; } = "Good";

        [Display(Name = "Purchase Date")]
        [DataType(DataType.Date)]
        public DateTime? PurchaseDate { get; set; }

        [Column(TypeName = "decimal(10,2)")]
        [Range(0, 100000)]
        public decimal? Price { get; set; }

        [StringLength(100)]
        [Display(Name = "Shelf Location")]
        public string? ShelfLocation { get; set; }

        // Navigation
        [ForeignKey("BookId")]
        public virtual Book? Book { get; set; }

        public virtual ICollection<Borrowing> Borrowings { get; set; } = new List<Borrowing>();
    }
}
