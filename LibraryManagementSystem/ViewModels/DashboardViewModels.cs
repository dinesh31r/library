namespace LibraryManagementSystem.ViewModels
{
    public class AdminDashboardViewModel
    {
        public int TotalBooks { get; set; }
        public int TotalCopies { get; set; }
        public int AvailableCopies { get; set; }
        public int IssuedBooks { get; set; }
        public int OverdueBooks { get; set; }
        public int TotalUsers { get; set; }
        public int TotalLibrarians { get; set; }
        public int PendingReservations { get; set; }
        public decimal OutstandingFines { get; set; }
        public Dictionary<string, int> MonthlyIssued { get; set; } = new();
        public Dictionary<string, int> MonthlyReturned { get; set; } = new();
        public Dictionary<string, int> BooksByCategory { get; set; } = new();
        public List<MostBorrowedBookViewModel> MostBorrowed { get; set; } = new();
    }

    public class LibrarianDashboardViewModel
    {
        public int TotalBooks { get; set; }
        public int AvailableCopies { get; set; }
        public int IssuedBooks { get; set; }
        public int TodayIssues { get; set; }
        public int TodayReturns { get; set; }
        public int OverdueBooks { get; set; }
        public int PendingReservations { get; set; }
        public decimal OutstandingFines { get; set; }
    }

    public class UserDashboardViewModel
    {
        public int CurrentlyBorrowed { get; set; }
        public int DueSoon { get; set; }
        public int OverdueCount { get; set; }
        public decimal OutstandingFines { get; set; }
        public int ActiveReservations { get; set; }
        public List<BorrowingItemViewModel> ActiveBorrowings { get; set; } = new();
        public List<string> Alerts { get; set; } = new();
    }

    public class MostBorrowedBookViewModel
    {
        public string Title { get; set; } = string.Empty;
        public string Author { get; set; } = string.Empty;
        public int BorrowCount { get; set; }
    }

    public class BorrowingItemViewModel
    {
        public int BorrowingId { get; set; }
        public string BookTitle { get; set; } = string.Empty;
        public string Author { get; set; } = string.Empty;
        public string AccessionNumber { get; set; } = string.Empty;
        public DateTime IssueDate { get; set; }
        public DateTime DueDate { get; set; }
        public int RenewalCount { get; set; }
        public bool IsOverdue => DueDate < DateTime.UtcNow;
        public int DaysRemaining => (DueDate - DateTime.UtcNow).Days;
    }
}
