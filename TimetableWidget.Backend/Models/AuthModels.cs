namespace TimetableWidget.Backend.Models;

public class LoginRequest
{
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}

public class LoginResponse
{
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
    public string State { get; set; } = string.Empty;
}

public class AuthStatusResponse
{
    public bool IsAuthenticated { get; set; }
    public string State { get; set; } = string.Empty;
}
