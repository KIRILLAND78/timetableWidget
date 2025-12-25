using Microsoft.AspNetCore.Mvc;
using TimetableWidget.Backend.Models;
using TimetableWidget.Backend.Services;

namespace TimetableWidget.Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly ITimetableService _timetableService;
    private readonly ILogger<AuthController> _logger;

    public AuthController(
        ITimetableService timetableService,
        ILogger<AuthController> logger)
    {
        _timetableService = timetableService;
        _logger = logger;
    }

    [HttpPost("login")]
    public async Task<ActionResult<LoginResponse>> Login([FromBody] LoginRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))
        {
            return BadRequest(new LoginResponse
            {
                Success = false,
                Message = "Email и пароль обязательны",
                State = "Error"
            });
        }

        _logger.LogInformation("Login request for email: {Email}", request.Email);

        var result = await _timetableService.LoginAsync(request.Email, request.Password);

        if (!result.Success)
        {
            return Unauthorized(result);
        }

        return Ok(result);
    }

    [HttpPost("logout")]
    public async Task<ActionResult> Logout()
    {
        _logger.LogInformation("Logout request");

        var success = await _timetableService.LogoutAsync();

        if (!success)
        {
            return StatusCode(500, new { message = "Ошибка при выходе" });
        }

        return Ok(new { message = "Успешный выход" });
    }

    [HttpGet("status")]
    public async Task<ActionResult<AuthStatusResponse>> GetStatus()
    {
        var status = await _timetableService.GetAuthStatusAsync();
        return Ok(status);
    }
}
