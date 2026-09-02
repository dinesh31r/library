namespace LibraryManagementSystem.Models
{
    public enum BookCopyStatus
    {
        Available,
        Issued,
        Reserved,
        Lost,
        Damaged,
        Maintenance
    }

    public enum BorrowingStatus
    {
        Issued,
        Returned,
        Overdue,
        Lost
    }

    public enum ReservationStatus
    {
        Pending,
        Ready,
        Fulfilled,
        Cancelled,
        Expired
    }

    public enum FineStatus
    {
        Pending,
        Paid,
        Waived
    }

    public enum NotificationType
    {
        BookIssued,
        BookDueSoon,
        BookOverdue,
        ReservationReady,
        ReservationExpired,
        FineGenerated,
        FinePaid,
        General
    }
}
