using System.Net;
using System.Text;
using System.Text.Json;
using TimetableWidget.Backend.Models;

namespace TimetableWidget.Backend.Services;

public class TimetableService : ITimetableService
{
    private readonly ITokenStore _tokenStore;
    private readonly ISettingsService _settingsService;
    private readonly ILogger<TimetableService> _logger;
    private readonly HttpClient _httpClient;

    private string _state = "Loading";
    private DateTime _lastUpdate = DateTime.MinValue;
    private bool _isToday = true;

    private const string ApiBaseUrl = "https://online.chuvsu.ru/api/v2";

    public TimetableService(
        ITokenStore tokenStore,
        ISettingsService settingsService,
        ILogger<TimetableService> logger,
        IHttpClientFactory httpClientFactory)
    {
        _tokenStore = tokenStore;
        _settingsService = settingsService;
        _logger = logger;
        _httpClient = httpClientFactory.CreateClient();

        // Check initial auth status
        var settings = _settingsService.GetSettings();
        var token = _tokenStore.GetToken();

        if (settings.Session == 0 || string.IsNullOrEmpty(token))
        {
            _state = "Not logged";
        }
        else
        {
            _state = "Logged";
        }
    }

    public async Task<LoginResponse> LoginAsync(string email, string password)
    {
        try
        {
            _logger.LogInformation("Attempting login for user: {Email}", email);

            // Clear existing data
            await LogoutAsync();

            using var request = new HttpRequestMessage(HttpMethod.Post, $"{ApiBaseUrl}/token");

            var credentials = Convert.ToBase64String(Encoding.UTF8.GetBytes($"{email}:{password}"));
            request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Basic", credentials);
            
            var response = await _httpClient.SendAsync(request);
            var jsonStream = await response.Content.ReadAsStreamAsync();
            var r = await response.Content.ReadAsStringAsync();
            var jsonDoc = await JsonDocument.ParseAsync(jsonStream);

            // Check for authentication errors
            if (jsonDoc.RootElement.TryGetProperty("status", out var statusProp))
            {
                var status = statusProp.GetString();
                if (status == "unauthorized" || status == "error")
                {
                    _state = "Wrong credentials";
                    _logger.LogWarning("Login failed: Wrong credentials");
                    return new LoginResponse
                    {
                        Success = false,
                        Message = "Неверный логин/пароль",
                        State = _state
                    };
                }
            }

            // Extract token and session
            var token = jsonDoc.RootElement.GetProperty("message").GetProperty("token").GetString();
            var sessionId = jsonDoc.RootElement.GetProperty("message").GetProperty("id").GetInt32();

            if (string.IsNullOrEmpty(token))
            {
                throw new Exception("Token is null or empty");
            }

            // Save credentials
            _tokenStore.SetToken(token);
            var settings = _settingsService.GetSettings();
            settings.Session = sessionId;
            _settingsService.SaveSettings(settings);

            _state = "Nominal";
            _lastUpdate = DateTime.MinValue;

            _logger.LogInformation("Login successful for session: {SessionId}", sessionId);

            return new LoginResponse
            {
                Success = true,
                Message = "Успешный вход",
                State = _state
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Login failed with error");
            _state = "Error";
            await LogoutAsync();

            return new LoginResponse
            {
                Success = false,
                Message = "Ошибка соединения",
                State = _state
            };
        }
    }

    public async Task<bool> LogoutAsync()
    {
        try
        {
            _tokenStore.Clear();
            var settings = _settingsService.GetSettings();
            settings.Session = 0;
            _settingsService.SaveSettings(settings);

            _state = "Not logged";
            _lastUpdate = DateTime.MinValue;

            _logger.LogInformation("Logout successful");
            return await Task.FromResult(true);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Logout failed");
            return false;
        }
    }

    public async Task<AuthStatusResponse> GetAuthStatusAsync()
    {
        var settings = _settingsService.GetSettings();
        var token = _tokenStore.GetToken();

        var isAuthenticated = settings.Session != 0 && !string.IsNullOrEmpty(token);

        return await Task.FromResult(new AuthStatusResponse
        {
            IsAuthenticated = isAuthenticated,
            State = _state
        });
    }

    public async Task<TimetableResponse> GetTimetableAsync(bool today = true)
    {
        var response = new TimetableResponse
        {
            State = _state,
            LastUpdate = _lastUpdate
        };

        try
        {
            var settings = _settingsService.GetSettings();
            var token = _tokenStore.GetToken();

            if (settings.Session == 0 || string.IsNullOrEmpty(token))
            {
                response.State = "Not logged";
                return response;
            }

            // Check if update is needed
            var forcedUpdate = false;
            var lastUpdateNextDay = _lastUpdate.AddDays(1).ToUniversalTime().AddHours(3).AddMinutes(-10).Date;
            var todayDate = DateTime.UtcNow.AddHours(3).Date;

            if (lastUpdateNextDay < todayDate)
            {
                forcedUpdate = true;
                _isToday = true;
            }

            if (!forcedUpdate && _lastUpdate > DateTime.Now.AddMinutes(-30))
            {
                // Use cached data
                response.State = _state;
                return response;
            }

            // Fetch timetable
            var endpoint = _isToday ? "today" : "tomorrow";
            using var request = new HttpRequestMessage(HttpMethod.Get, $"{ApiBaseUrl}/schedule/{endpoint}");

            var authToken = $"{settings.Session}:{token}";
            request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Token", authToken);

            var httpResponse = await _httpClient.SendAsync(request);
            httpResponse.EnsureSuccessStatusCode();

            var json = await httpResponse.Content.ReadAsStringAsync();
            var jsonDoc = JsonDocument.Parse(json);

            var items = new List<TimetableItem>();
            var switchToTomorrow = _isToday;

            if (jsonDoc.RootElement.TryGetProperty("items", out var itemsProperty))
            {
                if (itemsProperty.ValueKind != JsonValueKind.Array || itemsProperty.GetArrayLength() > 0)
                {
                    foreach (var itemVK in itemsProperty.EnumerateObject())
                    {
                        foreach (var lesson in itemVK.Value.EnumerateArray())
                        {
                            var subgroup = lesson.GetProperty("subgroup").GetInt32();

                            if (settings.Group != 0 && !(subgroup == 0 || subgroup == settings.Group))
                                continue;

                            var endTime = DateTime.Parse(lesson.GetProperty("end_time").GetString()!);
                            if (endTime > DateTime.UtcNow.AddHours(3).AddMinutes(10))
                            {
                                switchToTomorrow = false;
                            }

                            var item = new TimetableItem
                            {
                                Discipline = lesson.GetProperty("discipline").GetString() ?? "-",
                                StartTime = lesson.GetProperty("start_time").GetString() ?? "-",
                                EndTime = lesson.GetProperty("end_time").GetString() ?? "-",
                                Cabinet = lesson.GetProperty("cabinet").GetProperty("name").GetString() ?? "-",
                                Type = lesson.GetProperty("type").GetProperty("short").GetString() ?? "-",
                                Pair = lesson.GetProperty("pair").GetInt32()
                            };

                            items.Add(item);
                        }
                    }
                }
            }

            // If all lessons are over, switch to tomorrow
            if (switchToTomorrow && _isToday)
            {
                _isToday = false;
                return await GetTimetableAsync(false);
            }

            _lastUpdate = DateTime.Now;
            _state = "Nominal";

            response.State = _state;
            response.Items = items;
            response.LastUpdate = _lastUpdate;
            response.DayName = GetDayName();
            response.WeekDayName = GetWeekDayName();

            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch timetable");
            _state = "Error";
            response.State = _state;
            return response;
        }
    }

    private string GetDayName()
    {
        if (_lastUpdate == DateTime.MinValue)
            return "Загрузка...";

        var forDate = DateTime.Now;
        if (!_isToday)
            forDate = forDate.AddDays(1);

        return _isToday ? $"сегодня, {GetWeekDayName()}" : $"завтра, {GetWeekDayName()}";
    }

    private string GetWeekDayName()
    {
        if (_lastUpdate == DateTime.MinValue)
            return "...";

        var forDate = DateTime.Now;
        if (!_isToday)
            forDate = forDate.AddDays(1);

        var dayNames = new[] { "Воскресенье", "Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота" };
        return dayNames[(int)forDate.DayOfWeek];
    }
}
