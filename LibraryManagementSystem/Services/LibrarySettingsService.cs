using LibraryManagementSystem.Data;
using LibraryManagementSystem.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;

namespace LibraryManagementSystem.Services
{
    public class LibrarySettingsService : ILibrarySettingsService
    {
        private readonly ApplicationDbContext _context;
        private readonly IMemoryCache _cache;
        private const string CacheKey = "LibrarySettings";

        public LibrarySettingsService(ApplicationDbContext context, IMemoryCache cache)
        {
            _context = context;
            _cache = cache;
        }

        /// <summary>
        /// Returns cached library settings. Creates defaults if none exist.
        /// </summary>
        public async Task<LibrarySetting> GetSettingsAsync()
        {
            if (_cache.TryGetValue(CacheKey, out LibrarySetting? cached) && cached != null)
                return cached;

            var settings = await _context.LibrarySettings.FirstOrDefaultAsync();
            if (settings == null)
            {
                settings = new LibrarySetting();
                _context.LibrarySettings.Add(settings);
                await _context.SaveChangesAsync();
            }

            _cache.Set(CacheKey, settings, TimeSpan.FromMinutes(30));
            return settings;
        }

        public async Task UpdateSettingsAsync(LibrarySetting settings)
        {
            var existing = await _context.LibrarySettings.FirstOrDefaultAsync();
            if (existing == null)
            {
                _context.LibrarySettings.Add(settings);
            }
            else
            {
                existing.MaxBooksPerUser = settings.MaxBooksPerUser;
                existing.DefaultBorrowingDays = settings.DefaultBorrowingDays;
                existing.MaxRenewals = settings.MaxRenewals;
                existing.FinePerDay = settings.FinePerDay;
                existing.ReservationExpiryDays = settings.ReservationExpiryDays;
                existing.LibraryName = settings.LibraryName;
                existing.LibraryEmail = settings.LibraryEmail;
                existing.LibraryPhone = settings.LibraryPhone;
                existing.LibraryAddress = settings.LibraryAddress;
                existing.BlockIssueOnOverdue = settings.BlockIssueOnOverdue;
                existing.BlockIssueOnFine = settings.BlockIssueOnFine;
            }

            await _context.SaveChangesAsync();
            _cache.Remove(CacheKey);
        }
    }
}
