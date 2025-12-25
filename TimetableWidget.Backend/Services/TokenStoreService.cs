using Microsoft.AspNetCore.DataProtection;
using System.Text;

namespace TimetableWidget.Backend.Services;

public class TokenStoreService : ITokenStore
{
    private readonly IDataProtectionProvider _dataProtectionProvider;
    private readonly string _storagePath;
    private readonly ILogger<TokenStoreService> _logger;

    public TokenStoreService(
        IDataProtectionProvider dataProtectionProvider,
        ILogger<TokenStoreService> logger)
    {
        _dataProtectionProvider = dataProtectionProvider;
        _logger = logger;

        var baseFolder = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        var appFolder = Path.Combine(baseFolder, "TimetableWidget");

        if (!Directory.Exists(appFolder))
        {
            Directory.CreateDirectory(appFolder);
            _logger.LogInformation("Created app folder: {Folder}", appFolder);
        }

        _storagePath = Path.Combine(appFolder, "token.dat");
    }

    public string? GetToken()
    {
        try
        {
            if (!File.Exists(_storagePath))
            {
                _logger.LogWarning("Token file does not exist");
                return null;
            }

            var protectedData = File.ReadAllBytes(_storagePath);
            if (protectedData.Length == 0)
            {
                _logger.LogWarning("Token file is empty");
                return null;
            }

            var protector = _dataProtectionProvider.CreateProtector("TimetableWidget.Token");
            var unprotectedData = protector.Unprotect(protectedData);
            var token = Encoding.UTF8.GetString(unprotectedData);

            _logger.LogDebug("Token retrieved successfully");
            return token;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to get token");
            return null;
        }
    }

    public void SetToken(string token)
    {
        try
        {
            var protector = _dataProtectionProvider.CreateProtector("TimetableWidget.Token");
            var tokenBytes = Encoding.UTF8.GetBytes(token);
            var protectedData = protector.Protect(tokenBytes);

            File.WriteAllBytes(_storagePath, protectedData);
            _logger.LogInformation("Token saved successfully");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to save token");
            throw;
        }
    }

    public void Clear()
    {
        try
        {
            if (File.Exists(_storagePath))
            {
                File.Delete(_storagePath);
                _logger.LogInformation("Token cleared");
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to clear token");
            throw;
        }
    }
}
