using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LibraryManagementSystem.Models
{
    public class Book
    {
        [Key]
        public int BookId { get; set; }

        [Required]
        [StringLength(20)]
        [Display(Name = "ISBN")]
        public string ISBN { get; set; } = string.Empty;

        [Required]
        [StringLength(300)]
        public string Title { get; set; } = string.Empty;

        [StringLength(3000)]
        public string? Description { get; set; }

        [Required]
        [Display(Name = "Author")]
        public int AuthorId { get; set; }

        [Required]
        [Display(Name = "Category")]
        public int CategoryId { get; set; }

        [Required]
        [Display(Name = "Publisher")]
        public int PublisherId { get; set; }

        [Display(Name = "Publication Year")]
        [Range(1000, 2100)]
        public int? PublicationYear { get; set; }

        [StringLength(50)]
        public string? Edition { get; set; }

        [StringLength(50)]
        public string? Language { get; set; } = "English";

        [Required]
        [Display(Name = "Total Copies")]
        [Range(0, 10000)]
        public int TotalCopies { get; set; }

        [Display(Name = "Available Copies")]
        [Range(0, 10000)]
        public int AvailableCopies { get; set; }

        [StringLength(100)]
        [Display(Name = "Shelf Location")]
        public string? ShelfLocation { get; set; }

        [StringLength(500)]
        [Display(Name = "Cover Image")]
        public string? CoverImage { get; set; }

        [Display(Name = "Active")]
        public bool IsActive { get; set; } = true;

        [Display(Name = "Created At")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [Display(Name = "Updated At")]
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        [ForeignKey("AuthorId")]
        public virtual Author? Author { get; set; }

        [ForeignKey("CategoryId")]
        public virtual Category? Category { get; set; }

        [ForeignKey("PublisherId")]
        public virtual Publisher? Publisher { get; set; }

        public virtual ICollection<BookCopy> BookCopies { get; set; } = new List<BookCopy>();
        public virtual ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
    }
}
