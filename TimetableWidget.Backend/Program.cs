using Microsoft.AspNetCore.DataProtection;
using TimetableWidget.Backend.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddOpenApi();

// Configure CORS for JavaScript access from Cinnamon Desklet and local frontends
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// Configure Data Protection for cross-platform token encryption
var dataProtectionPath = Path.Combine(
    Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
    "TimetableWidget",
    "DataProtection-Keys");

builder.Services.AddDataProtection()
    .PersistKeysToFileSystem(new DirectoryInfo(dataProtectionPath))
    .SetApplicationName("TimetableWidget");

// Register services
builder.Services.AddSingleton<ITokenStore, TokenStoreService>();
builder.Services.AddSingleton<ISettingsService, SettingsService>();
builder.Services.AddSingleton<ITimetableService, TimetableService>();

// Configure HttpClient
builder.Services.AddHttpClient();

// Configure logging
builder.Logging.ClearProviders();
builder.Logging.AddConsole();
builder.Logging.AddDebug();

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.UseDeveloperExceptionPage();
}

// Enable CORS
app.UseCors("AllowAll");

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

// Add a simple root endpoint
app.MapGet("/", () => new
{
    name = "TimetableWidget Backend API",
    version = "1.0.0",
    status = "running",
    endpoints = new[]
    {
        "POST /api/auth/login",
        "POST /api/auth/logout",
        "GET  /api/auth/status",
        "GET  /api/timetable/today",
        "GET  /api/timetable/tomorrow",
        "GET  /api/settings",
        "PUT  /api/settings",
        "POST /api/settings/reset-position"
    }
});

app.Run();
