using TimetableWidget.Backend.Models;

namespace TimetableWidget.Backend.Services;

public interface ISettingsService
{
    SettingsModel GetSettings();
    void SaveSettings(SettingsModel settings);
    void ResetPosition();
}
