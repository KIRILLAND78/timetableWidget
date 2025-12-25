const Desklet = imports.ui.desklet;
const St = imports.gi.St;
const Soup = imports.gi.Soup;
const Lang = imports.lang;
const Mainloop = imports.mainloop;
const Settings = imports.ui.settings;
const Clutter = imports.gi.Clutter;
const GLib = imports.gi.GLib;
const Gio = imports.gi.Gio;
const ModalDialog = imports.ui.modalDialog;

// HTTP client for API calls
const httpSession = new Soup.SessionAsync();
Soup.Session.prototype.add_feature.call(httpSession, new Soup.ProxyResolverDefault());

function TimetableDesklet(metadata, desklet_id) {
    this._init(metadata, desklet_id);
}

TimetableDesklet.prototype = {
    __proto__: Desklet.Desklet.prototype,

    _init: function(metadata, desklet_id) {
        Desklet.Desklet.prototype._init.call(this, metadata, desklet_id);

        this.metadata = metadata;
        this.desklet_id = desklet_id;

        // Settings
        this.settings = new Settings.DeskletSettings(this, this.metadata.uuid, desklet_id);
        this.settings.bind("group", "group", this.on_setting_changed);
        this.settings.bind("transparency", "transparency", this.on_setting_changed);
        this.settings.bind("backendUrl", "backendUrl", this.on_setting_changed);
        this.settings.bind("updateInterval", "updateInterval", this.on_setting_changed);

        // State
        this.isAuthenticated = false;
        this.timetableData = null;
        this.updateTimer = null;

        // Setup UI
        this.setupUI();

        // Check auth status and start
        this.checkAuthStatus();

        // Click handler for authentication
        this.actor.set_reactive(true);
        this.actor.connect('button-press-event', Lang.bind(this, this.on_desklet_clicked));
    },

    setupUI: function() {
        // Main container
        this.window = new St.BoxLayout({
            vertical: true,
            style_class: 'timetable-container'
        });

        // Header
        this.headerLabel = new St.Label({
            text: 'Расписание',
            style_class: 'timetable-header'
        });
        this.window.add(this.headerLabel);

        // Day name
        this.dayLabel = new St.Label({
            text: 'Загрузка...',
            style_class: 'timetable-day'
        });
        this.window.add(this.dayLabel);

        // Lessons container
        this.lessonsBox = new St.BoxLayout({
            vertical: true,
            style_class: 'timetable-lessons'
        });
        this.window.add(this.lessonsBox);

        // Status label
        this.statusLabel = new St.Label({
            text: 'Нажмите для входа',
            style_class: 'timetable-status'
        });
        this.window.add(this.statusLabel);

        this.setContent(this.window);
        this.updateTransparency();
    },

    on_setting_changed: function() {
        this.updateTransparency();
        if (this.isAuthenticated) {
            this.saveSettingsToBackend();
            this.updateTimetable();
        }
    },

    updateTransparency: function() {
        let opacity = this.transparency / 100.0 * 255;
        this.window.set_opacity(opacity);
    },

    on_desklet_clicked: function(actor, event) {
        if (event.get_button() === 1) { // Left click
            if (!this.isAuthenticated) {
                this.showLoginDialog();
            } else {
                this.updateTimetable();
            }
        } else if (event.get_button() === 3) { // Right click - context menu handled by Cinnamon
            return false;
        }
        return true;
    },

    showLoginDialog: function() {
        let dialog = new ModalDialog.ModalDialog();

        // Title
        let label = new St.Label({
            text: 'Авторизация ЧувГУ',
            style: 'font-size: 16pt; font-weight: bold; margin-bottom: 10px;'
        });
        dialog.contentLayout.add(label);

        // Email entry
        let emailLabel = new St.Label({ text: 'Email:' });
        dialog.contentLayout.add(emailLabel);

        let emailEntry = new St.Entry({
            hint_text: 'student@example.com',
            style: 'width: 300px; margin-bottom: 10px;'
        });
        dialog.contentLayout.add(emailEntry);

        // Password entry
        let passwordLabel = new St.Label({ text: 'Пароль:' });
        dialog.contentLayout.add(passwordLabel);

        let passwordEntry = new St.Entry({
            hint_text: '••••••••',
            style: 'width: 300px; margin-bottom: 10px;'
        });
        passwordEntry.clutter_text.set_password_char('\u2022');
        dialog.contentLayout.add(passwordEntry);

        // Error label
        let errorLabel = new St.Label({
            text: '',
            style: 'color: red; margin-top: 5px;'
        });
        dialog.contentLayout.add(errorLabel);

        // Buttons
        dialog.setButtons([
            {
                label: 'Отмена',
                action: Lang.bind(this, function() {
                    dialog.close();
                })
            },
            {
                label: 'Войти',
                action: Lang.bind(this, function() {
                    let email = emailEntry.get_text();
                    let password = passwordEntry.get_text();

                    if (!email || !password) {
                        errorLabel.set_text('Заполните все поля');
                        return;
                    }

                    this.login(email, password, function(success, message) {
                        if (success) {
                            dialog.close();
                        } else {
                            errorLabel.set_text(message);
                        }
                    });
                })
            }
        ]);

        dialog.open();
    },

    checkAuthStatus: function() {
        let url = this.backendUrl + '/api/auth/status';

        this.apiGet(url, Lang.bind(this, function(status, response) {
            if (status === 200 && response) {
                try {
                    let data = JSON.parse(response);
                    this.isAuthenticated = data.isAuthenticated;

                    if (this.isAuthenticated) {
                        this.statusLabel.set_text('Подключено');
                        this.loadSettingsFromBackend();
                        this.startUpdateTimer();
                        this.updateTimetable();
                    } else {
                        this.statusLabel.set_text('Нажмите для входа');
                    }
                } catch (e) {
                    global.logError('Failed to parse auth status: ' + e);
                }
            }
        }));
    },

    login: function(email, password, callback) {
        let url = this.backendUrl + '/api/auth/login';
        let data = JSON.stringify({
            email: email,
            password: password
        });

        this.apiPost(url, data, Lang.bind(this, function(status, response) {
            if (status === 200 && response) {
                try {
                    let result = JSON.parse(response);
                    if (result.success) {
                        this.isAuthenticated = true;
                        this.statusLabel.set_text('Подключено');
                        this.loadSettingsFromBackend();
                        this.startUpdateTimer();
                        this.updateTimetable();
                        callback(true, 'Успешный вход');
                    } else {
                        callback(false, result.message || 'Ошибка входа');
                    }
                } catch (e) {
                    callback(false, 'Ошибка обработки ответа');
                    global.logError('Login parse error: ' + e);
                }
            } else {
                callback(false, 'Ошибка соединения');
            }
        }));
    },

    updateTimetable: function() {
        let url = this.backendUrl + '/api/timetable/today';

        this.apiGet(url, Lang.bind(this, function(status, response) {
            if (status === 200 && response) {
                try {
                    let data = JSON.parse(response);
                    this.timetableData = data;
                    this.renderTimetable(data);
                } catch (e) {
                    global.logError('Failed to parse timetable: ' + e);
                    this.statusLabel.set_text('Ошибка загрузки');
                }
            } else if (status === 401) {
                // Unauthorized - need to login again
                this.isAuthenticated = false;
                this.statusLabel.set_text('Требуется авторизация');
                this.stopUpdateTimer();
            } else {
                this.statusLabel.set_text('Ошибка соединения');
            }
        }));
    },

    renderTimetable: function(data) {
        // Clear previous lessons
        this.lessonsBox.destroy_all_children();

        // Update header
        this.headerLabel.set_text('Расписание на ' + (data.dayName || ''));
        this.statusLabel.set_text(data.state || 'OK');

        if (!data.items || data.items.length === 0) {
            let emptyLabel = new St.Label({
                text: 'Нет занятий',
                style_class: 'timetable-empty'
            });
            this.lessonsBox.add(emptyLabel);
            return;
        }

        // Render lessons (max 5 visible)
        let visibleCount = 0;
        for (let i = 0; i < data.items.length && visibleCount < 5; i++) {
            let item = data.items[i];

            // Filter by group if set
            if (this.group !== 0 && item.subgroup !== 0 && item.subgroup !== this.group) {
                continue;
            }

            let lessonBox = new St.BoxLayout({
                vertical: true,
                style_class: 'timetable-lesson'
            });

            // Discipline name
            let disciplineLabel = new St.Label({
                text: item.discipline || '-',
                style_class: 'timetable-discipline'
            });
            lessonBox.add(disciplineLabel);

            // Time and place
            let infoText = (item.startTime || '') + ' - ' + (item.endTime || '') +
                          '   ' + (item.cabinet || '') + '   ' + (item.type || '');
            let infoLabel = new St.Label({
                text: infoText,
                style_class: 'timetable-info'
            });
            lessonBox.add(infoLabel);

            this.lessonsBox.add(lessonBox);
            visibleCount++;
        }

        if (data.items.length > 5) {
            let moreLabel = new St.Label({
                text: '+ ещё ' + (data.items.length - 5) + ' пар',
                style_class: 'timetable-more'
            });
            this.lessonsBox.add(moreLabel);
        }
    },

    loadSettingsFromBackend: function() {
        let url = this.backendUrl + '/api/settings';

        this.apiGet(url, Lang.bind(this, function(status, response) {
            if (status === 200 && response) {
                try {
                    let settings = JSON.parse(response);
                    // Update local settings from backend
                    if (settings.group !== undefined) {
                        this.group = settings.group;
                    }
                    if (settings.transparency !== undefined) {
                        this.transparency = settings.transparency;
                        this.updateTransparency();
                    }
                } catch (e) {
                    global.logError('Failed to load settings: ' + e);
                }
            }
        }));
    },

    saveSettingsToBackend: function() {
        let url = this.backendUrl + '/api/settings';
        let data = JSON.stringify({
            x: 0,
            y: 0,
            session: 0,
            group: this.group,
            transparency: this.transparency,
            draggable: true,
            debugMode: false
        });

        this.apiPut(url, data, function(status, response) {
            if (status !== 200) {
                global.logError('Failed to save settings');
            }
        });
    },

    startUpdateTimer: function() {
        if (this.updateTimer) {
            Mainloop.source_remove(this.updateTimer);
        }

        this.updateTimer = Mainloop.timeout_add_seconds(
            this.updateInterval,
            Lang.bind(this, function() {
                this.updateTimetable();
                return true; // Continue timer
            })
        );
    },

    stopUpdateTimer: function() {
        if (this.updateTimer) {
            Mainloop.source_remove(this.updateTimer);
            this.updateTimer = null;
        }
    },

    // API helper methods
    apiGet: function(url, callback) {
        let message = Soup.Message.new('GET', url);
        httpSession.queue_message(message, function(session, message) {
            callback(message.status_code, message.response_body.data);
        });
    },

    apiPost: function(url, data, callback) {
        let message = Soup.Message.new('POST', url);
        message.set_request('application/json', Soup.MemoryUse.COPY, data);
        httpSession.queue_message(message, function(session, message) {
            callback(message.status_code, message.response_body.data);
        });
    },

    apiPut: function(url, data, callback) {
        let message = Soup.Message.new('PUT', url);
        message.set_request('application/json', Soup.MemoryUse.COPY, data);
        httpSession.queue_message(message, function(session, message) {
            callback(message.status_code, message.response_body.data);
        });
    },

    on_desklet_removed: function() {
        this.stopUpdateTimer();
    }
};

function main(metadata, desklet_id) {
    return new TimetableDesklet(metadata, desklet_id);
}
