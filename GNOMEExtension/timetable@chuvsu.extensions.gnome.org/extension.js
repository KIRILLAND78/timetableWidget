import GObject from 'gi://GObject';
import St from 'gi://St';
import Clutter from 'gi://Clutter';
import Soup from 'gi://Soup';
import GLib from 'gi://GLib';
import Gio from 'gi://Gio';

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import * as ModalDialog from 'resource:///org/gnome/shell/ui/modalDialog.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

const TimetableIndicator = GObject.registerClass(
class TimetableIndicator extends PanelMenu.Button {
    _init(settings, httpSession) {
        super._init(0.0, 'ЧувГУ Расписание');

        this._settings = settings;
        this._httpSession = httpSession;
        this._isAuthenticated = false;
        this._timetableData = null;
        this._updateTimer = null;

        // Panel button with icon and label
        let box = new St.BoxLayout({
            style_class: 'panel-status-menu-box'
        });

        this._icon = new St.Icon({
            icon_name: 'x-office-calendar-symbolic',
            style_class: 'system-status-icon'
        });
        box.add_child(this._icon);

        this._label = new St.Label({
            text: 'ЧувГУ',
            y_align: Clutter.ActorAlign.CENTER
        });
        box.add_child(this._label);

        this.add_child(box);

        // Create popup menu
        this._buildMenu();

        // Check auth status
        this._checkAuthStatus();

        // Setup update timer
        this._setupUpdateTimer();

        // Connect to settings changes
        this._settingsChangedId = this._settings.connect('changed', () => {
            this._onSettingsChanged();
        });
    }

    _buildMenu() {
        // Header
        this._headerItem = new PopupMenu.PopupMenuItem('Расписание', {
            reactive: false,
            can_focus: false
        });
        this._headerItem.label.add_style_class_name('timetable-header');
        this.menu.addMenuItem(this._headerItem);

        // Day label
        this._dayItem = new PopupMenu.PopupMenuItem('Загрузка...', {
            reactive: false,
            can_focus: false
        });
        this._dayItem.label.add_style_class_name('timetable-day');
        this.menu.addMenuItem(this._dayItem);

        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        // Lessons section
        this._lessonsSection = new PopupMenu.PopupMenuSection();
        this.menu.addMenuItem(this._lessonsSection);

        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        // Status label
        this._statusItem = new PopupMenu.PopupMenuItem('Нажмите для входа', {
            reactive: false,
            can_focus: false
        });
        this._statusItem.label.add_style_class_name('timetable-status');
        this.menu.addMenuItem(this._statusItem);

        // Login/Refresh button
        this._loginButton = new PopupMenu.PopupMenuItem('Войти');
        this._loginButton.connect('activate', () => {
            if (this._isAuthenticated) {
                this._updateTimetable();
            } else {
                this._showLoginDialog();
            }
        });
        this.menu.addMenuItem(this._loginButton);

        // Logout button
        this._logoutButton = new PopupMenu.PopupMenuItem('Выйти');
        this._logoutButton.connect('activate', () => {
            this._logout();
        });
        this.menu.addMenuItem(this._logoutButton);
        this._logoutButton.actor.visible = false;
    }

    _showLoginDialog() {
        let dialog = new ModalDialog.ModalDialog({
            styleClass: 'timetable-login-dialog'
        });

        // Title
        let titleLabel = new St.Label({
            text: 'Авторизация ЧувГУ',
            style: 'font-size: 16pt; font-weight: bold; padding-bottom: 10px;'
        });
        dialog.contentLayout.add_child(titleLabel);

        // Email
        let emailLabel = new St.Label({text: 'Email:'});
        dialog.contentLayout.add_child(emailLabel);

        let emailEntry = new St.Entry({
            hint_text: 'student@example.com',
            can_focus: true,
            style: 'width: 300px; margin-bottom: 10px;'
        });
        dialog.contentLayout.add_child(emailEntry);

        // Password
        let passwordLabel = new St.Label({text: 'Пароль:'});
        dialog.contentLayout.add_child(passwordLabel);

        let passwordEntry = new St.Entry({
            hint_text: '••••••••',
            can_focus: true,
            style: 'width: 300px; margin-bottom: 10px;'
        });
        passwordEntry.clutter_text.set_password_char('\u2022');
        dialog.contentLayout.add_child(passwordEntry);

        // Error label
        let errorLabel = new St.Label({
            text: '',
            style: 'color: red; margin-top: 5px;'
        });
        dialog.contentLayout.add_child(errorLabel);

        // Buttons
        dialog.setButtons([
            {
                label: 'Отмена',
                action: () => {
                    dialog.close();
                },
                key: Clutter.KEY_Escape
            },
            {
                label: 'Войти',
                action: () => {
                    let email = emailEntry.get_text();
                    let password = passwordEntry.get_text();

                    if (!email || !password) {
                        errorLabel.set_text('Заполните все поля');
                        return;
                    }

                    errorLabel.set_text('Вход...');

                    this._login(email, password, (success, message) => {
                        if (success) {
                            dialog.close();
                        } else {
                            errorLabel.set_text(message);
                        }
                    });
                },
                default: true
            }
        ]);

        dialog.open();
        global.stage.set_key_focus(emailEntry);
    }

    _checkAuthStatus() {
        let backendUrl = this._settings.get_string('backend-url');
        this._apiGet(backendUrl + '/api/auth/status', (status, response) => {
            if (status === 200 && response) {
                try {
                    let data = JSON.parse(response);
                    this._isAuthenticated = data.isAuthenticated;

                    if (this._isAuthenticated) {
                        this._statusItem.label.set_text('Подключено');
                        this._loginButton.label.set_text('Обновить');
                        this._logoutButton.actor.visible = true;
                        this._updateTimetable();
                    } else {
                        this._statusItem.label.set_text('Нажмите для входа');
                        this._loginButton.label.set_text('Войти');
                        this._logoutButton.actor.visible = false;
                    }
                } catch (e) {
                    log('Failed to parse auth status: ' + e);
                }
            } else {
                this._statusItem.label.set_text('Backend недоступен');
            }
        });
    }

    _login(email, password, callback) {
        let backendUrl = this._settings.get_string('backend-url');
        let data = {
            email: email,
            password: password
        };

        this._apiPost(backendUrl + '/api/auth/login', data, (status, response) => {
            if (status === 200 && response) {
                try {
                    let result = JSON.parse(response);
                    if (result.success) {
                        this._isAuthenticated = true;
                        this._statusItem.label.set_text('Подключено');
                        this._loginButton.label.set_text('Обновить');
                        this._logoutButton.actor.visible = true;
                        this._updateTimetable();
                        callback(true, 'Успешный вход');
                    } else {
                        callback(false, result.message || 'Ошибка входа');
                    }
                } catch (e) {
                    callback(false, 'Ошибка обработки ответа');
                }
            } else {
                callback(false, 'Ошибка соединения');
            }
        });
    }

    _logout() {
        let backendUrl = this._settings.get_string('backend-url');
        this._apiPost(backendUrl + '/api/auth/logout', null, (status) => {
            if (status === 200) {
                this._isAuthenticated = false;
                this._statusItem.label.set_text('Вышли из системы');
                this._loginButton.label.set_text('Войти');
                this._logoutButton.actor.visible = false;
                this._lessonsSection.removeAll();
                this._label.set_text('ЧувГУ');
                this._stopUpdateTimer();
            }
        });
    }

    _updateTimetable() {
        let backendUrl = this._settings.get_string('backend-url');
        this._apiGet(backendUrl + '/api/timetable/today', (status, response) => {
            if (status === 200 && response) {
                try {
                    let data = JSON.parse(response);
                    this._timetableData = data;
                    this._renderTimetable(data);
                } catch (e) {
                    log('Failed to parse timetable: ' + e);
                    this._statusItem.label.set_text('Ошибка загрузки');
                }
            } else if (status === 401) {
                this._isAuthenticated = false;
                this._statusItem.label.set_text('Требуется авторизация');
                this._loginButton.label.set_text('Войти');
                this._logoutButton.actor.visible = false;
                this._stopUpdateTimer();
            } else {
                this._statusItem.label.set_text('Ошибка соединения');
            }
        });
    }

    _renderTimetable(data) {
        this._lessonsSection.removeAll();

        this._headerItem.label.set_text('Расписание на ' + (data.dayName || ''));
        this._dayItem.label.set_text(data.weekDayName || '');
        this._statusItem.label.set_text(data.state || 'OK');

        if (data.items && data.items.length > 0) {
            this._label.set_text(data.items.length + ' пар');

            let groupFilter = this._settings.get_int('group');
            let visibleCount = 0;

            for (let i = 0; i < data.items.length && visibleCount < 5; i++) {
                let item = data.items[i];

                if (groupFilter !== 0 && item.subgroup !== 0 && item.subgroup !== groupFilter) {
                    continue;
                }

                let lessonItem = new PopupMenu.PopupMenuItem(
                    item.discipline || '-',
                    {reactive: false, can_focus: false}
                );
                lessonItem.label.add_style_class_name('timetable-discipline');

                let infoLabel = new St.Label({
                    text: (item.startTime || '') + ' - ' + (item.endTime || '') +
                          '  ' + (item.cabinet || '') + '  ' + (item.type || ''),
                    style_class: 'timetable-info'
                });
                lessonItem.actor.add_child(infoLabel);

                this._lessonsSection.addMenuItem(lessonItem);
                visibleCount++;
            }

            if (data.items.length > 5) {
                let moreItem = new PopupMenu.PopupMenuItem(
                    '+ ещё ' + (data.items.length - 5) + ' пар',
                    {reactive: false, can_focus: false}
                );
                moreItem.label.add_style_class_name('timetable-more');
                this._lessonsSection.addMenuItem(moreItem);
            }
        } else {
            this._label.set_text('ЧувГУ');
            let emptyItem = new PopupMenu.PopupMenuItem('Нет занятий', {
                reactive: false,
                can_focus: false
            });
            emptyItem.label.add_style_class_name('timetable-empty');
            this._lessonsSection.addMenuItem(emptyItem);
        }
    }

    _setupUpdateTimer() {
        this._stopUpdateTimer();

        if (this._isAuthenticated) {
            let interval = this._settings.get_int('update-interval');
            this._updateTimer = GLib.timeout_add_seconds(
                GLib.PRIORITY_DEFAULT,
                interval,
                () => {
                    this._updateTimetable();
                    return GLib.SOURCE_CONTINUE;
                }
            );
        }
    }

    _stopUpdateTimer() {
        if (this._updateTimer) {
            GLib.Source.remove(this._updateTimer);
            this._updateTimer = null;
        }
    }

    _onSettingsChanged() {
        this._setupUpdateTimer();
        if (this._timetableData) {
            this._renderTimetable(this._timetableData);
        }
    }

    _apiGet(url, callback) {
        let message = Soup.Message.new('GET', url);
        this._httpSession.send_and_read_async(message, GLib.PRIORITY_DEFAULT, null, (session, result) => {
            try {
                let bytes = session.send_and_read_finish(result);
                let decoder = new TextDecoder('utf-8');
                let response = decoder.decode(bytes.get_data());
                callback(message.status_code, response);
            } catch (e) {
                callback(0, null);
            }
        });
    }

    _apiPost(url, data, callback) {
        let message = Soup.Message.new('POST', url);
        if (data) {
            let bodyData = JSON.stringify(data);
            message.set_request_body_from_bytes('application/json', new GLib.Bytes(bodyData));
        }
        this._httpSession.send_and_read_async(message, GLib.PRIORITY_DEFAULT, null, (session, result) => {
            try {
                let bytes = session.send_and_read_finish(result);
                let decoder = new TextDecoder('utf-8');
                let response = decoder.decode(bytes.get_data());
                callback(message.status_code, response);
            } catch (e) {
                callback(0, null);
            }
        });
    }

    destroy() {
        if (this._settingsChangedId) {
            this._settings.disconnect(this._settingsChangedId);
            this._settingsChangedId = null;
        }
        this._stopUpdateTimer();
        super.destroy();
    }
});

export default class TimetableExtension extends Extension {
    enable() {
        this._settings = this.getSettings();
        this._httpSession = new Soup.Session();
        this._indicator = new TimetableIndicator(this._settings, this._httpSession);
        Main.panel.addToStatusArea(this.uuid, this._indicator);
    }

    disable() {
        if (this._indicator) {
            this._indicator.destroy();
            this._indicator = null;
        }
        this._settings = null;
        this._httpSession = null;
    }
}
