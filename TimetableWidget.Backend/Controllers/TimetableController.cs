using Microsoft.AspNetCore.Mvc;
using TimetableWidget.Backend.Models;
using TimetableWidget.Backend.Services;

namespace TimetableWidget.Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TimetableController : ControllerBase
{
    private readonly ITimetableService _timetableService;
    private readonly ILogger<TimetableController> _logger;

    public TimetableController(
        ITimetableService timetableService,
        ILogger<TimetableController> logger)
    {
        _timetableService = timetableService;
        _logger = logger;
    }

    [HttpGet("today")]
    public async Task<ActionResult<TimetableResponse>> GetToday()
    {
        _logger.LogDebug("Fetching timetable for today");
        var result = await _timetableService.GetTimetableAsync(today: true);
        return Ok(result);
    }

    [HttpGet("tomorrow")]
    public async Task<ActionResult<TimetableResponse>> GetTomorrow()
    {
        _logger.LogDebug("Fetching timetable for tomorrow");
        var result = await _timetableService.GetTimetableAsync(today: false);
        return Ok(result);
    }
}
