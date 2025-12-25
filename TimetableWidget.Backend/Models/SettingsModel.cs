namespace TimetableWidget.Backend.Models;

public class SettingsModel
{
    public int X { get; set; }
    public int Y { get; set; }
    public int Session { get; set; }
    public int Group { get; set; }
    public int Transparency { get; set; } = 100;
    public bool Draggable { get; set; } = true;
    public bool DebugMode { get; set; } = false;
}
