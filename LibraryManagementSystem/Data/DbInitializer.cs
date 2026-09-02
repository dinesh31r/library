using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using LibraryManagementSystem.Models;

namespace LibraryManagementSystem.Data
{
    /// <summary>
    /// Seeds initial roles, admin account, and sample data on first startup.
    /// </summary>
    public static class DbInitializer
    {
        public static async Task InitializeAsync(IServiceProvider serviceProvider, IConfiguration configuration)
        {
            using var scope = serviceProvider.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
            var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();
            var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole>>();
            var logger = scope.ServiceProvider.GetRequiredService<ILogger<ApplicationDbContext>>();

            try
            {
                await context.Database.EnsureCreatedAsync();
                // Verify schema by checking if roles table exists
                _ = await roleManager.RoleExistsAsync("Admin");
                logger.LogInformation("Database schema verified successfully.");
            }
            catch (Exception ex)
            {
                logger.LogWarning("Database initialization reset required: {Message}", ex.Message);
                await context.Database.EnsureDeletedAsync();
                await context.Database.EnsureCreatedAsync();
                logger.LogInformation("Fresh database created successfully.");
            }

            // ── Roles ───────────────────────────────────────────────
            string[] roles = { "Admin", "Librarian", "User" };
            foreach (var role in roles)
            {
                if (!await roleManager.RoleExistsAsync(role))
                {
                    await roleManager.CreateAsync(new IdentityRole(role));
                    logger.LogInformation("Created role: {Role}", role);
                }
            }

            // ── Admin Account ───────────────────────────────────────
            var adminEmail = configuration["SeedData:AdminEmail"] ?? "admin@library.com";
            var adminPassword = configuration["SeedData:AdminPassword"] ?? "Admin@123456";
            var adminUser = await userManager.FindByEmailAsync(adminEmail);
            if (adminUser == null)
            {
                adminUser = new ApplicationUser
                {
                    UserName = adminEmail,
                    Email = adminEmail,
                    FullName = "System Administrator",
                    EmailConfirmed = true,
                    IsActive = true,
                    PhoneNumber = "+91-9000000001",
                    Address = "Library Admin Office",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                var result = await userManager.CreateAsync(adminUser, adminPassword);
                if (result.Succeeded)
                {
                    await userManager.AddToRoleAsync(adminUser, "Admin");
                    logger.LogInformation("Admin user created: {Email}", adminEmail);
                }
                else
                {
                    logger.LogError("Failed to create admin: {Errors}",
                        string.Join(", ", result.Errors.Select(e => e.Description)));
                }
            }

            // ── Librarian Account ───────────────────────────────────
            var librarianEmail = configuration["SeedData:LibrarianEmail"] ?? "librarian@library.com";
            var librarianPassword = configuration["SeedData:LibrarianPassword"] ?? "Librarian@123456";
            var librarianUser = await userManager.FindByEmailAsync(librarianEmail);
            if (librarianUser == null)
            {
                librarianUser = new ApplicationUser
                {
                    UserName = librarianEmail,
                    Email = librarianEmail,
                    FullName = "Jane Librarian",
                    EmailConfirmed = true,
                    IsActive = true,
                    PhoneNumber = "+91-9000000002",
                    Address = "Library Front Desk",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                var result = await userManager.CreateAsync(librarianUser, librarianPassword);
                if (result.Succeeded)
                {
                    await userManager.AddToRoleAsync(librarianUser, "Librarian");
                    logger.LogInformation("Librarian user created: {Email}", librarianEmail);
                }
            }

            // ── User Account ────────────────────────────────────────
            var userEmail = configuration["SeedData:UserEmail"] ?? "user@library.com";
            var userPassword = configuration["SeedData:UserPassword"] ?? "User@123456";
            var normalUser = await userManager.FindByEmailAsync(userEmail);
            if (normalUser == null)
            {
                normalUser = new ApplicationUser
                {
                    UserName = userEmail,
                    Email = userEmail,
                    FullName = "Rahul Student",
                    EmailConfirmed = true,
                    IsActive = true,
                    PhoneNumber = "+91-9000000003",
                    Address = "Student Hostel, Room 204",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                var result = await userManager.CreateAsync(normalUser, userPassword);
                if (result.Succeeded)
                {
                    await userManager.AddToRoleAsync(normalUser, "User");
                    logger.LogInformation("User account created: {Email}", userEmail);
                }
            }

            // ── Sample Data (only if empty) ─────────────────────────
            if (!await context.Authors.AnyAsync())
            {
                await SeedSampleDataAsync(context, adminUser, librarianUser, normalUser, logger);
            }
        }

        private static async Task SeedSampleDataAsync(
            ApplicationDbContext context,
            ApplicationUser admin,
            ApplicationUser librarian,
            ApplicationUser normalUser,
            ILogger logger)
        {
            // ── Authors ─────────────────────────────────────────────
            var authors = new List<Author>
            {
                new() { Name = "R.K. Narayan", Biography = "Rasipuram Krishnaswami Iyer Narayanaswami, known as R.K. Narayan, was an Indian writer.", Country = "India", DateOfBirth = new DateTime(1906, 10, 10) },
                new() { Name = "Chetan Bhagat", Biography = "Indian author, columnist, and screenwriter.", Country = "India", DateOfBirth = new DateTime(1974, 4, 22) },
                new() { Name = "J.K. Rowling", Biography = "British author best known for the Harry Potter series.", Country = "United Kingdom", DateOfBirth = new DateTime(1965, 7, 31) },
                new() { Name = "George Orwell", Biography = "English novelist, essayist, journalist and critic.", Country = "United Kingdom", DateOfBirth = new DateTime(1903, 6, 25) },
                new() { Name = "Amish Tripathi", Biography = "Indian author known for mythological fiction.", Country = "India", DateOfBirth = new DateTime(1974, 10, 18) },
                new() { Name = "Robert C. Martin", Biography = "American software engineer and author known as Uncle Bob.", Country = "United States", DateOfBirth = new DateTime(1952, 12, 5) },
                new() { Name = "Andrew Hunt", Biography = "Author of The Pragmatic Programmer.", Country = "United States" },
                new() { Name = "Arundhati Roy", Biography = "Indian author who won the Man Booker Prize.", Country = "India", DateOfBirth = new DateTime(1961, 11, 24) }
            };
            context.Authors.AddRange(authors);
            await context.SaveChangesAsync();

            // ── Categories ──────────────────────────────────────────
            var categories = new List<Category>
            {
                new() { Name = "Fiction", Description = "Novels, short stories, and creative literary works" },
                new() { Name = "Non-Fiction", Description = "Factual and informational books" },
                new() { Name = "Science Fiction", Description = "Speculative fiction dealing with imaginative concepts" },
                new() { Name = "Computer Science", Description = "Programming, algorithms, and software engineering" },
                new() { Name = "History", Description = "Historical accounts and analyses" },
                new() { Name = "Philosophy", Description = "Philosophical texts and analyses" },
                new() { Name = "Mathematics", Description = "Mathematical textbooks and references" },
                new() { Name = "Biography", Description = "Biographical and autobiographical works" },
                new() { Name = "Self-Help", Description = "Personal development and motivational books" },
                new() { Name = "Fantasy", Description = "Fantasy literature and world-building fiction" }
            };
            context.Categories.AddRange(categories);
            await context.SaveChangesAsync();

            // ── Publishers ──────────────────────────────────────────
            var publishers = new List<Publisher>
            {
                new() { Name = "Penguin Random House", Address = "New Delhi, India", Email = "contact@penguin.in", Phone = "+91-11-40000000", Website = "https://www.penguin.co.in" },
                new() { Name = "HarperCollins India", Address = "Noida, UP, India", Email = "info@harpercollins.co.in", Phone = "+91-120-4044800", Website = "https://www.harpercollins.co.in" },
                new() { Name = "Pearson Education", Address = "Bangalore, India", Email = "info@pearson.com", Phone = "+91-80-40000000", Website = "https://www.pearson.com" },
                new() { Name = "O'Reilly Media", Address = "Sebastopol, CA, USA", Email = "info@oreilly.com", Website = "https://www.oreilly.com" },
                new() { Name = "Bloomsbury Publishing", Address = "London, UK", Email = "info@bloomsbury.com", Website = "https://www.bloomsbury.com" }
            };
            context.Publishers.AddRange(publishers);
            await context.SaveChangesAsync();

            // ── Books ───────────────────────────────────────────────
            var books = new List<Book>
            {
                new() { ISBN = "978-0-14-018938-5", Title = "The Guide", Description = "A novel set in the fictional town of Malgudi, following the story of Raju.", AuthorId = authors[0].AuthorId, CategoryId = categories[0].CategoryId, PublisherId = publishers[0].PublisherId, PublicationYear = 1958, Language = "English", TotalCopies = 3, AvailableCopies = 3, ShelfLocation = "A-01-01" },
                new() { ISBN = "978-8-12-911515-0", Title = "Five Point Someone", Description = "A story about three friends at IIT and how they try to survive the system.", AuthorId = authors[1].AuthorId, CategoryId = categories[0].CategoryId, PublisherId = publishers[1].PublisherId, PublicationYear = 2004, Language = "English", TotalCopies = 4, AvailableCopies = 4, ShelfLocation = "A-01-02" },
                new() { ISBN = "978-0-7475-3269-6", Title = "Harry Potter and the Philosopher's Stone", Description = "The first book in the Harry Potter series.", AuthorId = authors[2].AuthorId, CategoryId = categories[9].CategoryId, PublisherId = publishers[4].PublisherId, PublicationYear = 1997, Language = "English", TotalCopies = 5, AvailableCopies = 5, ShelfLocation = "B-02-01" },
                new() { ISBN = "978-0-452-28423-4", Title = "1984", Description = "A dystopian novel about totalitarian governance.", AuthorId = authors[3].AuthorId, CategoryId = categories[2].CategoryId, PublisherId = publishers[0].PublisherId, PublicationYear = 1949, Language = "English", TotalCopies = 3, AvailableCopies = 3, ShelfLocation = "B-03-01" },
                new() { ISBN = "978-0-452-28424-1", Title = "Animal Farm", Description = "A satirical allegorical novella reflecting events of the Russian Revolution.", AuthorId = authors[3].AuthorId, CategoryId = categories[0].CategoryId, PublisherId = publishers[0].PublisherId, PublicationYear = 1945, Language = "English", TotalCopies = 3, AvailableCopies = 3, ShelfLocation = "B-03-02" },
                new() { ISBN = "978-9-38-067099-0", Title = "The Immortals of Meluha", Description = "A mythological fiction novel about the Shiva Trilogy.", AuthorId = authors[4].AuthorId, CategoryId = categories[9].CategoryId, PublisherId = publishers[1].PublisherId, PublicationYear = 2010, Language = "English", TotalCopies = 4, AvailableCopies = 4, ShelfLocation = "C-01-01" },
                new() { ISBN = "978-0-13-235088-4", Title = "Clean Code", Description = "A handbook of agile software craftsmanship.", AuthorId = authors[5].AuthorId, CategoryId = categories[3].CategoryId, PublisherId = publishers[2].PublisherId, PublicationYear = 2008, Language = "English", TotalCopies = 3, AvailableCopies = 3, ShelfLocation = "D-01-01" },
                new() { ISBN = "978-0-20-161622-4", Title = "The Pragmatic Programmer", Description = "Your journey to mastery in software development.", AuthorId = authors[6].AuthorId, CategoryId = categories[3].CategoryId, PublisherId = publishers[2].PublisherId, PublicationYear = 1999, Language = "English", TotalCopies = 3, AvailableCopies = 3, ShelfLocation = "D-01-02" },
                new() { ISBN = "978-0-06-097749-7", Title = "The God of Small Things", Description = "A novel that explores how the 'weights and measures' of social norms affect everyday life.", AuthorId = authors[7].AuthorId, CategoryId = categories[0].CategoryId, PublisherId = publishers[1].PublisherId, PublicationYear = 1997, Language = "English", TotalCopies = 2, AvailableCopies = 2, ShelfLocation = "A-02-01" },
                new() { ISBN = "978-8-12-911806-9", Title = "2 States", Description = "The story of a cross-cultural love marriage.", AuthorId = authors[1].AuthorId, CategoryId = categories[0].CategoryId, PublisherId = publishers[1].PublisherId, PublicationYear = 2009, Language = "English", TotalCopies = 4, AvailableCopies = 4, ShelfLocation = "A-01-03" },
                new() { ISBN = "978-0-7475-4215-2", Title = "Harry Potter and the Chamber of Secrets", Description = "The second book in the Harry Potter series.", AuthorId = authors[2].AuthorId, CategoryId = categories[9].CategoryId, PublisherId = publishers[4].PublisherId, PublicationYear = 1998, Language = "English", TotalCopies = 4, AvailableCopies = 4, ShelfLocation = "B-02-02" },
                new() { ISBN = "978-0-7475-4629-7", Title = "Harry Potter and the Prisoner of Azkaban", Description = "The third book in the Harry Potter series.", AuthorId = authors[2].AuthorId, CategoryId = categories[9].CategoryId, PublisherId = publishers[4].PublisherId, PublicationYear = 1999, Language = "English", TotalCopies = 3, AvailableCopies = 3, ShelfLocation = "B-02-03" }
            };
            context.Books.AddRange(books);
            await context.SaveChangesAsync();

            // ── Book Copies ─────────────────────────────────────────
            int accessionCounter = 1001;
            foreach (var book in books)
            {
                for (int i = 0; i < book.TotalCopies; i++)
                {
                    context.BookCopies.Add(new BookCopy
                    {
                        BookId = book.BookId,
                        AccessionNumber = $"ACC-{accessionCounter:D5}",
                        Barcode = $"LIB-{accessionCounter:D5}",
                        Status = BookCopyStatus.Available,
                        Condition = "Good",
                        PurchaseDate = DateTime.UtcNow.AddMonths(-new Random(accessionCounter).Next(1, 24)),
                        Price = 250m + (accessionCounter % 10) * 50m,
                        ShelfLocation = book.ShelfLocation
                    });
                    accessionCounter++;
                }
            }
            await context.SaveChangesAsync();

            // ── Library Settings ────────────────────────────────────
            if (!context.LibrarySettings.Any())
            {
                context.LibrarySettings.Add(new LibrarySetting
                {
                    MaxBooksPerUser = 5,
                    DefaultBorrowingDays = 14,
                    MaxRenewals = 2,
                    FinePerDay = 5.00m,
                    ReservationExpiryDays = 2,
                    LibraryName = "Central Library — Library Management System",
                    LibraryEmail = "library@institution.edu",
                    LibraryPhone = "+91-80-12345678",
                    LibraryAddress = "Main Campus, Building A, Ground Floor"
                });
                await context.SaveChangesAsync();
            }

            // ── Sample Borrowings ────────────────────────────────────
            var firstCopy = context.BookCopies.FirstOrDefault(bc => bc.BookId == books[0].BookId && bc.Status == BookCopyStatus.Available);
            if (firstCopy != null)
            {
                var borrowing = new Borrowing
                {
                    UserId = normalUser.Id,
                    BookCopyId = firstCopy.BookCopyId,
                    IssuedBy = librarian.Id,
                    IssueDate = DateTime.UtcNow.AddDays(-10),
                    DueDate = DateTime.UtcNow.AddDays(4),
                    Status = BorrowingStatus.Issued
                };
                context.Borrowings.Add(borrowing);
                firstCopy.Status = BookCopyStatus.Issued;
                books[0].AvailableCopies--;

                context.Notifications.Add(new Notification
                {
                    UserId = normalUser.Id,
                    Title = "Book Issued",
                    Message = $"'{books[0].Title}' has been issued to you. Due date: {borrowing.DueDate:MMM dd, yyyy}.",
                    Type = NotificationType.BookIssued
                });
            }

            await context.SaveChangesAsync();
            logger.LogInformation("Sample data seeded successfully.");
        }
    }
}
