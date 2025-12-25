# TimetableWidget - Виджет расписания ЧувГУ

Кросс-платформенный виджет для отображения расписания занятий Чувашского государственного университета.

## 🎯 Архитектура

Проект разделен на **backend** и **frontend** для поддержки разных платформ:

```
┌──────────────────────────────────────────┐
│   Backend (ASP.NET Core Web API)         │
│   - REST API                             │
│   - Бизнес-логика                        │
│   - Работа с API ЧувГУ                   │
│   - Хранение настроек и токенов          │
│   - Поддержка Windows и Linux            │
└───────────────┬──────────────────────────┘
                │ HTTP/REST API
    ┌───────────┴───────────┐
    │                       │
┌───▼────────┐    ┌────────▼─────────┐
│  Windows   │    │ Cinnamon Desklet │
│   Forms    │    │   (JavaScript)   │
│  Frontend  │    │   Frontend       │
└────────────┘    └──────────────────┘
```

## 📁 Структура проекта

```
timetableWidget/
├── TimetableWidget.Backend/      # ASP.NET Core API бэкенд
│   ├── Controllers/               # REST API контроллеры
│   ├── Services/                  # Бизнес-логика
│   ├── Models/                    # DTO модели
│   └── README.md                  # Документация бэкенда
│
├── CinnamonDesklet/              # Linux Cinnamon Desklet
│   ├── timetable@chuvsu/         # Исходники desklet
│   ├── install.sh                # Скрипт установки
│   └── README.md                 # Документация desklet
│
├── KDEPlasmoid/                  # KDE Plasma Widget
│   ├── org.chuvsu.timetable/     # Исходники plasmoid
│   ├── install.sh                # Скрипт установки
│   └── README.md                 # Документация plasmoid
│
├── GNOMEExtension/               # GNOME Shell Extension
│   ├── timetable@chuvsu.../      # Исходники extension
│   ├── install.sh                # Скрипт установки
│   └── README.md                 # Документация extension
│
├── ChusvSUTimetableWF-main/      # Windows Forms фронтенд (оригинальный)
│   └── ...                        # Будет адаптирован для работы с API
│
└── README.md                      # Этот файл
```

## 🚀 Быстрый старт

### 1. Запустить Backend

```bash
cd TimetableWidget.Backend
dotnet restore
dotnet run
```

Backend запустится на `http://localhost:5000`

### 2. Запустить Frontend

#### Windows Forms (будет реализовано)
```bash
cd ChusvSUTimetableWF-main
# TODO: адаптировать для работы с API
```

#### Linux (Cinnamon Desklet)
```bash
cd CinnamonDesklet
./install.sh
# Затем: ПКМ на рабочий стол → Добавить виджеты → Desklets → ЧувГУ Расписание
```

См. [CinnamonDesklet/README.md](CinnamonDesklet/README.md) для подробной инструкции.

#### Linux (KDE Plasma Widget)
```bash
cd KDEPlasmoid
./install.sh
# Затем: ПКМ на рабочий стол → Добавить виджеты → ЧувГУ Расписание
```

См. [KDEPlasmoid/README.md](KDEPlasmoid/README.md) для подробной инструкции.

#### Linux (GNOME Shell Extension)
```bash
cd GNOMEExtension
./install.sh
# Затем: gnome-extensions enable timetable@chuvsu.extensions.gnome.org
# Или перезапустите GNOME Shell (Alt+F2 → 'r')
```

См. [GNOMEExtension/README.md](GNOMEExtension/README.md) для подробной инструкции.

## 🔧 Текущий статус

### ✅ Готово
- [x] Backend API с REST endpoints
- [x] Авторизация через API ЧувГУ
- [x] Получение расписания
- [x] Управление настройками
- [x] Кросс-платформенное шифрование токенов
- [x] CORS для доступа из JavaScript
- [x] **Cinnamon Desklet для Linux** (JavaScript/GJS)
  - [x] GTK диалог авторизации
  - [x] Встроенные настройки Cinnamon
  - [x] Отображение расписания
  - [x] Автоматическое обновление
- [x] **KDE Plasma Widget для Linux** (QML/JavaScript)
  - [x] Qt диалог авторизации
  - [x] Встроенные настройки KDE
  - [x] Отображение расписания на рабочем столе и панели
  - [x] Автоматическое обновление
- [x] **GNOME Shell Extension для Linux** (JavaScript/GJS)
  - [x] Modal диалог авторизации
  - [x] Встроенные настройки GNOME (GSettings)
  - [x] Панельный индикатор с popup меню
  - [x] Автоматическое обновление

### 🚧 В разработке
- [ ] Адаптация Windows Forms для работы с API

## 📋 API Endpoints

См. [Backend README](TimetableWidget.Backend/README.md) для полной документации API.

Основные endpoints:
- `POST /api/auth/login` - Авторизация
- `GET /api/timetable/today` - Расписание на сегодня
- `GET /api/timetable/tomorrow` - Расписание на завтра
- `GET /api/settings` - Получить настройки
- `PUT /api/settings` - Обновить настройки

## 🔐 Безопасность

- Токены шифруются с использованием ASP.NET Core Data Protection API
- Поддержка Windows DPAPI и Linux file-based encryption
- Пароли никогда не хранятся локально

## 🐛 Разработка

### Тестирование API

Используйте файл `TimetableWidget.Backend/api-examples.http` с расширением REST Client в VS Code.

### Логирование

Для включения debug логов установите в `appsettings.Development.json`:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Debug"
    }
  }
}
```

## 📝 Авторы

- **Код виджета**: Казаков Кирилл Валерьевич, КТ-31-21
- **API расписания (Мой ЧувГУ)**: Петрянкин Даниил Евгеньевич, КТ-31-21
- **Дизайн**: Гаврилов Александр Сергеевич, КТ-42-20

## 📄 Лицензия

См. соглашения:
- [Пользовательское соглашение](https://online.chuvsu.ru/doc/user_agreement)
- [Политика конфиденциальности](https://online.chuvsu.ru/doc/privacy_policy)
