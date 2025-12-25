using TimetableWidget.Backend.Models;

namespace TimetableWidget.Backend.Services;

public interface ITimetableService
{
    Task<LoginResponse> LoginAsync(string email, string password);
    Task<bool> LogoutAsync();
    Task<AuthStatusResponse> GetAuthStatusAsync();
    Task<TimetableResponse> GetTimetableAsync(bool today = true);
}
