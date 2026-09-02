using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using LibraryManagementSystem.Models;

namespace LibraryManagementSystem.Data
{
    /// <summary>
    /// Application database context with Identity support and all library entities.
    /// </summary>
    public class ApplicationDbContext : IdentityDbContext<ApplicationUser>
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options)
        {
        }

        public DbSet<Book> Books => Set<Book>();
        public DbSet<Author> Authors => Set<Author>();
        public DbSet<Category> Categories => Set<Category>();
        public DbSet<Publisher> Publishers => Set<Publisher>();
        public DbSet<BookCopy> BookCopies => Set<BookCopy>();
        public DbSet<Borrowing> Borrowings => Set<Borrowing>();
        public DbSet<Reservation> Reservations => Set<Reservation>();
        public DbSet<Fine> Fines => Set<Fine>();
        public DbSet<AuditLog> AuditLogs => Set<AuditLog>();
        public DbSet<LibrarySetting> LibrarySettings => Set<LibrarySetting>();
        public DbSet<Notification> Notifications => Set<Notification>();

        protected override void OnModelCreating(ModelBuilder builder)
        {
            base.OnModelCreating(builder);

            // ── Book ────────────────────────────────────────────────
            builder.Entity<Book>(entity =>
            {
                entity.HasIndex(b => b.ISBN).IsUnique();
                entity.HasIndex(b => b.Title);

                entity.HasOne(b => b.Author)
                      .WithMany(a => a.Books)
                      .HasForeignKey(b => b.AuthorId)
                      .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(b => b.Category)
                      .WithMany(c => c.Books)
                      .HasForeignKey(b => b.CategoryId)
                      .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(b => b.Publisher)
                      .WithMany(p => p.Books)
                      .HasForeignKey(b => b.PublisherId)
                      .OnDelete(DeleteBehavior.Restrict);
            });

            // ── Category ────────────────────────────────────────────
            builder.Entity<Category>(entity =>
            {
                entity.HasIndex(c => c.Name).IsUnique();
            });

            // ── BookCopy ────────────────────────────────────────────
            builder.Entity<BookCopy>(entity =>
            {
                entity.HasIndex(bc => bc.AccessionNumber).IsUnique();
                entity.HasIndex(bc => bc.Barcode).IsUnique();

                entity.HasOne(bc => bc.Book)
                      .WithMany(b => b.BookCopies)
                      .HasForeignKey(bc => bc.BookId)
                      .OnDelete(DeleteBehavior.Restrict);
            });

            // ── Borrowing ───────────────────────────────────────────
            builder.Entity<Borrowing>(entity =>
            {
                entity.HasIndex(b => b.Status);
                entity.HasIndex(b => b.DueDate);

                entity.HasOne(b => b.User)
                      .WithMany(u => u.Borrowings)
                      .HasForeignKey(b => b.UserId)
                      .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(b => b.BookCopy)
                      .WithMany(bc => bc.Borrowings)
                      .HasForeignKey(b => b.BookCopyId)
                      .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(b => b.IssuedByUser)
                      .WithMany()
                      .HasForeignKey(b => b.IssuedBy)
                      .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(b => b.ReturnedToUser)
                      .WithMany()
                      .HasForeignKey(b => b.ReturnedTo)
                      .OnDelete(DeleteBehavior.Restrict);
            });

            // ── Reservation ─────────────────────────────────────────
            builder.Entity<Reservation>(entity =>
            {
                entity.HasIndex(r => new { r.BookId, r.Status });

                entity.HasOne(r => r.User)
                      .WithMany(u => u.Reservations)
                      .HasForeignKey(r => r.UserId)
                      .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(r => r.Book)
                      .WithMany(b => b.Reservations)
                      .HasForeignKey(r => r.BookId)
                      .OnDelete(DeleteBehavior.Restrict);
            });

            // ── Fine ────────────────────────────────────────────────
            builder.Entity<Fine>(entity =>
            {
                entity.HasIndex(f => f.Status);

                entity.HasOne(f => f.User)
                      .WithMany(u => u.Fines)
                      .HasForeignKey(f => f.UserId)
                      .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(f => f.Borrowing)
                      .WithOne(b => b.Fine)
                      .HasForeignKey<Fine>(f => f.BorrowingId)
                      .OnDelete(DeleteBehavior.Restrict);
            });

            // ── AuditLog ────────────────────────────────────────────
            builder.Entity<AuditLog>(entity =>
            {
                entity.HasIndex(a => a.CreatedAt);
                entity.HasIndex(a => a.Action);

                entity.HasOne(a => a.User)
                      .WithMany()
                      .HasForeignKey(a => a.UserId)
                      .OnDelete(DeleteBehavior.SetNull);
            });

            // ── Notification ────────────────────────────────────────
            builder.Entity<Notification>(entity =>
            {
                entity.HasIndex(n => new { n.UserId, n.IsRead });
                entity.HasIndex(n => n.CreatedAt);

                entity.HasOne(n => n.User)
                      .WithMany(u => u.Notifications)
                      .HasForeignKey(n => n.UserId)
                      .OnDelete(DeleteBehavior.Cascade);
            });
        }
    }
}
