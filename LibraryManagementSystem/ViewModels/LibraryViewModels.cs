using System.ComponentModel.DataAnnotations;
using LibraryManagementSystem.Models;
using Microsoft.AspNetCore.Mvc.Rendering;

namespace LibraryManagementSystem.ViewModels
{
    public class BookListViewModel
    {
        public List<BookItemViewModel> Books { get; set; } = new();
        public string? SearchTerm { get; set; }
        public int? CategoryId { get; set; }
        public int? AuthorId { get; set; }
        public int? PublisherId { get; set; }
        public bool? AvailableOnly { get; set; }
        public int CurrentPage { get; set; } = 1;
        public int TotalPages { get; set; }
        public int TotalCount { get; set; }
        public List<SelectListItem> Categories { get; set; } = new();
        public List<SelectListItem> Authors { get; set; } = new();
        public List<SelectListItem> Publishers { get; set; } = new();
    }

    public class BookItemViewModel
    {
        public int BookId { get; set; }
        public string ISBN { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string Author { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public int AvailableCopies { get; set; }
        public int TotalCopies { get; set; }
        public string? CoverImage { get; set; }
        public bool IsActive { get; set; }
    }

    public class BookCreateViewModel
    {
        [Required]
        [StringLength(20)]
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
        [Display(Name = "Initial Copies")]
        [Range(1, 100)]
        public int InitialCopies { get; set; } = 1;

        [StringLength(100)]
        [Display(Name = "Shelf Location")]
        public string? ShelfLocation { get; set; }

        public List<SelectListItem> Authors { get; set; } = new();
        public List<SelectListItem> Categories { get; set; } = new();
        public List<SelectListItem> Publishers { get; set; } = new();
    }

    public class BookEditViewModel : BookCreateViewModel
    {
        public int BookId { get; set; }
        public bool IsActive { get; set; }
    }

    public class BookDetailViewModel
    {
        public int BookId { get; set; }
        public string ISBN { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string Author { get; set; } = string.Empty;
        public int AuthorId { get; set; }
        public string Category { get; set; } = string.Empty;
        public string Publisher { get; set; } = string.Empty;
        public int? PublicationYear { get; set; }
        public string? Edition { get; set; }
        public string? Language { get; set; }
        public int TotalCopies { get; set; }
        public int AvailableCopies { get; set; }
        public string? ShelfLocation { get; set; }
        public string? CoverImage { get; set; }
        public bool IsActive { get; set; }
        public List<BookCopyItemViewModel> Copies { get; set; } = new();
        public bool CanReserve { get; set; }
        public bool HasActiveReservation { get; set; }
    }

    public class BookCopyItemViewModel
    {
        public int BookCopyId { get; set; }
        public string AccessionNumber { get; set; } = string.Empty;
        public string Barcode { get; set; } = string.Empty;
        public BookCopyStatus Status { get; set; }
        public string? Condition { get; set; }
        public string? ShelfLocation { get; set; }
    }

    public class BookCopyCreateViewModel
    {
        public int BookId { get; set; }
        public string BookTitle { get; set; } = string.Empty;

        [Required]
        [StringLength(50)]
        [Display(Name = "Accession Number")]
        public string AccessionNumber { get; set; } = string.Empty;

        [Required]
        [StringLength(50)]
        public string Barcode { get; set; } = string.Empty;

        [StringLength(50)]
        public string? Condition { get; set; } = "Good";

        [Display(Name = "Purchase Date")]
        [DataType(DataType.Date)]
        public DateTime? PurchaseDate { get; set; }

        [Range(0, 100000)]
        public decimal? Price { get; set; }

        [StringLength(100)]
        [Display(Name = "Shelf Location")]
        public string? ShelfLocation { get; set; }
    }

    public class IssueBookViewModel
    {
        [Required]
        [Display(Name = "User")]
        public string UserId { get; set; } = string.Empty;

        [Required]
        [Display(Name = "Book Copy")]
        public int BookCopyId { get; set; }

        public string? UserName { get; set; }
        public string? BookTitle { get; set; }
        public string? AccessionNumber { get; set; }
    }

    public class ReturnBookViewModel
    {
        public int BorrowingId { get; set; }
        public string UserName { get; set; } = string.Empty;
        public string BookTitle { get; set; } = string.Empty;
        public string AccessionNumber { get; set; } = string.Empty;
        public DateTime IssueDate { get; set; }
        public DateTime DueDate { get; set; }
        public int OverdueDays { get; set; }
        public decimal CalculatedFine { get; set; }
        public decimal FinePerDay { get; set; }
        public string? Notes { get; set; }
    }

    public class UserListViewModel
    {
        public List<UserItemViewModel> Users { get; set; } = new();
        public string? SearchTerm { get; set; }
        public string? RoleFilter { get; set; }
        public int CurrentPage { get; set; } = 1;
        public int TotalPages { get; set; }
        public int TotalCount { get; set; }
    }

    public class UserItemViewModel
    {
        public string Id { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string? PhoneNumber { get; set; }
        public string Role { get; set; } = string.Empty;
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class UserCreateViewModel
    {
        [Required]
        [StringLength(100)]
        [Display(Name = "Full Name")]
        public string FullName { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        [StringLength(100, MinimumLength = 6)]
        [DataType(DataType.Password)]
        public string Password { get; set; } = string.Empty;

        [Phone]
        [Display(Name = "Phone Number")]
        public string? PhoneNumber { get; set; }

        [StringLength(250)]
        public string? Address { get; set; }

        [Required]
        public string Role { get; set; } = "User";
    }

    public class UserEditViewModel
    {
        public string Id { get; set; } = string.Empty;

        [Required]
        [StringLength(100)]
        [Display(Name = "Full Name")]
        public string FullName { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Phone]
        [Display(Name = "Phone Number")]
        public string? PhoneNumber { get; set; }

        [StringLength(250)]
        public string? Address { get; set; }

        [Required]
        public string Role { get; set; } = string.Empty;

        [Display(Name = "Active")]
        public bool IsActive { get; set; }
    }

    public class ReportFilterViewModel
    {
        public string ReportType { get; set; } = "issued";
        public DateTime? FromDate { get; set; }
        public DateTime? ToDate { get; set; }
        public int? CategoryId { get; set; }
        public int? AuthorId { get; set; }
        public string? Status { get; set; }
        public List<SelectListItem> Categories { get; set; } = new();
        public List<SelectListItem> Authors { get; set; } = new();
    }
}
