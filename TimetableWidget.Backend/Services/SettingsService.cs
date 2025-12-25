using System.Text.Json;
using TimetableWidget.Backend.Models;

namespace TimetableWidget.Backend.Services;

public class SettingsService : ISettingsService
{
    private readonly string _settingsPath;
    private readonly ILogger<SettingsService> _logger;
    private SettingsModel? _cachedSettings;

    public SettingsService(ILogger<SettingsService> logger)
    {
        _logger = logger;

        var baseFolder = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        var appFolder = Path.Combine(baseFolder, "TimetableWidget");

        if (!Directory.Exists(appFolder))
        {
            Directory.CreateDirectory(appFolder);
            _logger.LogInformation("Created app folder: {Folder}", appFolder);
        }

        _settingsPath = Path.Combine(appFolder, "settings.json");
    }

    public SettingsModel GetSettings()
    {
        if (_cachedSettings != null)
            return _cachedSettings;

        try
        {
            if (!File.Exists(_settingsPath))
            {
                _logger.LogInformation("Settings file does not exist, creating default");
                var defaultSettings = new SettingsModel();
                SaveSettings(defaultSettings);
                return defaultSettings;
            }

            var json = File.ReadAllText(_settingsPath);
            _cachedSettings = JsonSerializer.Deserialize<SettingsModel>(json) ?? new SettingsModel();
            _logger.LogDebug("Settings loaded successfully");

            return _cachedSettings;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to load settings, returning defaults");
            return new SettingsModel();
        }
    }

    public void SaveSettings(SettingsModel settings)
    {
        try
        {
            var json = JsonSerializer.Serialize(settings, new JsonSerializerOptions
            {
                WriteIndented = true
            });

            File.WriteAllText(_settingsPath, json);
            _cachedSettings = settings;

            _logger.LogInformation("Settings saved successfully");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to save settings");
            throw;
        }
    }

    public void ResetPosition()
    {
        var settings = GetSettings();
        settings.X = 5;
        settings.Y = 5;
        SaveSettings(settings);
        _logger.LogInformation("Position reset to (5, 5)");
    }
}
