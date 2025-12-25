namespace TimetableWidget.Backend.Models;

public class TimetableItem
{
    public string Discipline { get; set; } = string.Empty;
    public string StartTime { get; set; } = string.Empty;
    public string EndTime { get; set; } = string.Empty;
    public string Cabinet { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public int Pair { get; set; }
}

public class TimetableResponse
{
    public string State { get; set; } = string.Empty;
    public string DayName { get; set; } = string.Empty;
    public string WeekDayName { get; set; } = string.Empty;
    public List<TimetableItem> Items { get; set; } = new();
    public DateTime LastUpdate { get; set; }
}
