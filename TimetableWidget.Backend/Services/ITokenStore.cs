namespace TimetableWidget.Backend.Services;

public interface ITokenStore
{
    string? GetToken();
    void SetToken(string token);
    void Clear();
}
