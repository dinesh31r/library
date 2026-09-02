using LibraryManagementSystem.Models;

namespace LibraryManagementSystem.Services
{
    public interface ILibrarySettingsService
    {
        Task<LibrarySetting> GetSettingsAsync();
        Task UpdateSettingsAsync(LibrarySetting settings);
    }
}
