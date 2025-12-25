using Microsoft.AspNetCore.Mvc;
using TimetableWidget.Backend.Models;
using TimetableWidget.Backend.Services;

namespace TimetableWidget.Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SettingsController : ControllerBase
{
    private readonly ISettingsService _settingsService;
    private readonly ILogger<SettingsController> _logger;

    public SettingsController(
        ISettingsService settingsService,
        ILogger<SettingsController> logger)
    {
        _settingsService = settingsService;
        _logger = logger;
    }

    [HttpGet]
    public ActionResult<SettingsModel> GetSettings()
    {
        _logger.LogDebug("Fetching settings");
        var settings = _settingsService.GetSettings();
        return Ok(settings);
    }

    [HttpPut]
    public ActionResult<SettingsModel> UpdateSettings([FromBody] SettingsModel settings)
    {
        _logger.LogInformation("Updating settings");

        try
        {
            _settingsService.SaveSettings(settings);
            return Ok(settings);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to update settings");
            return StatusCode(500, new { message = "Ошибка при сохранении настроек" });
        }
    }

    [HttpPost("reset-position")]
    public ActionResult ResetPosition()
    {
        _logger.LogInformation("Resetting widget position");

        try
        {
            _settingsService.ResetPosition();
            var settings = _settingsService.GetSettings();
            return Ok(settings);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to reset position");
            return StatusCode(500, new { message = "Ошибка при сбросе позиции" });
        }
    }
}
