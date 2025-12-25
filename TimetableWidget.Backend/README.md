# TimetableWidget Backend API

REST API бэкенд для виджета расписания ЧувГУ. Поддерживает Windows и Linux.

## 🚀 Запуск

```bash
cd TimetableWidget.Backend
dotnet restore
dotnet run
```

По умолчанию API запускается на:
- HTTP: `http://localhost:5000`
- HTTPS: `https://localhost:5001`

## 📋 API Endpoints

### Авторизация

**POST** `/api/auth/login`
```json
{
  "email": "student@example.com",
  "password": "password123"
}
```

**POST** `/api/auth/logout`

**GET** `/api/auth/status`

### Расписание

**GET** `/api/timetable/today` - Получить расписание на сегодня

**GET** `/api/timetable/tomorrow` - Получить расписание на завтра

### Настройки

**GET** `/api/settings` - Получить настройки

**PUT** `/api/settings` - Обновить настройки
```json
{
  "x": 100,
  "y": 100,
  "session": 12345,
  "group": 1,
  "transparency": 80,
  "draggable": true,
  "debugMode": false
}
```

**POST** `/api/settings/reset-position` - Сбросить позицию виджета на (5, 5)

## 🔐 Хранение данных

### Windows
- Настройки: `%LOCALAPPDATA%\TimetableWidget\settings.json`
- Токен: `%LOCALAPPDATA%\TimetableWidget\token.dat` (зашифрован)
- Ключи шифрования: `%LOCALAPPDATA%\TimetableWidget\DataProtection-Keys\`

### Linux
- Настройки: `~/.local/share/TimetableWidget/settings.json`
- Токен: `~/.local/share/TimetableWidget/token.dat` (зашифрован)
- Ключи шифрования: `~/.local/share/TimetableWidget/DataProtection-Keys/`

## 🛠️ Технологии

- ASP.NET Core 10.0
- Data Protection API (кросс-платформенное шифрование)
- CORS включен для доступа из JavaScript frontends

## 🔧 Конфигурация

Для изменения портов отредактируйте `appsettings.json`:

```json
{
  "Urls": "http://localhost:5000;https://localhost:5001"
}
```

## 📝 Архитектура

```
Backend
├── Models         - DTO модели для API
├── Services       - Бизнес-логика
│   ├── TimetableService   - Работа с API ЧувГУ
│   ├── SettingsService    - Управление настройками
│   └── TokenStoreService  - Безопасное хранение токенов
└── Controllers    - REST API endpoints
    ├── AuthController
    ├── TimetableController
    └── SettingsController
```

## 🐛 Debug Mode

Включите debug логирование в `appsettings.Development.json`:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Debug",
      "Microsoft.AspNetCore": "Warning"
    }
  }
}
```
