"""Main window for TimetableWidget"""

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib

from .api_client import APIClient
from .config import Config


class LoginDialog(Gtk.Dialog):
    """Login dialog for authentication"""

    def __init__(self, parent):
        super().__init__(title="Авторизация ЧувГУ", parent=parent)
        self.add_buttons(
            Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
            Gtk.STOCK_OK, Gtk.ResponseType.OK
        )

        self.set_default_size(400, 200)
        box = self.get_content_area()
        box.set_spacing(10)
        box.set_margin_start(20)
        box.set_margin_end(20)
        box.set_margin_top(20)
        box.set_margin_bottom(20)

        # Title
        title = Gtk.Label()
        title.set_markup("<b>Вход в систему Мой ЧувГУ</b>")
        box.pack_start(title, False, False, 5)

        # Email
        email_label = Gtk.Label(label="Email:")
        email_label.set_halign(Gtk.Align.START)
        box.pack_start(email_label, False, False, 0)

        self.email_entry = Gtk.Entry()
        self.email_entry.set_placeholder_text("student@example.com")
        box.pack_start(self.email_entry, False, False, 0)

        # Password
        password_label = Gtk.Label(label="Пароль:")
        password_label.set_halign(Gtk.Align.START)
        box.pack_start(password_label, False, False, 0)

        self.password_entry = Gtk.Entry()
        self.password_entry.set_visibility(False)
        self.password_entry.set_placeholder_text("••••••••")
        box.pack_start(self.password_entry, False, False, 0)

        # Error label
        self.error_label = Gtk.Label()
        self.error_label.set_markup("<span color='red'></span>")
        box.pack_start(self.error_label, False, False, 5)

        self.show_all()

    def get_credentials(self):
        """Get entered credentials"""
        return self.email_entry.get_text(), self.password_entry.get_text()

    def show_error(self, message):
        """Show error message"""
        self.error_label.set_markup(f"<span color='red'>{message}</span>")


class SettingsDialog(Gtk.Dialog):
    """Settings dialog"""

    def __init__(self, parent, config):
        super().__init__(title="Настройки", parent=parent)
        self.config = config
        self.add_buttons(
            Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
            Gtk.STOCK_OK, Gtk.ResponseType.OK
        )

        self.set_default_size(400, 300)
        box = self.get_content_area()
        box.set_spacing(10)
        box.set_margin_start(20)
        box.set_margin_end(20)
        box.set_margin_top(20)
        box.set_margin_bottom(20)

        # Backend URL
        url_label = Gtk.Label(label="URL бэкенда:")
        url_label.set_halign(Gtk.Align.START)
        box.pack_start(url_label, False, False, 0)

        self.url_entry = Gtk.Entry()
        self.url_entry.set_text(config.backend_url)
        box.pack_start(self.url_entry, False, False, 0)

        # Group
        group_label = Gtk.Label(label="Подгруппа (0 = все):")
        group_label.set_halign(Gtk.Align.START)
        box.pack_start(group_label, False, False, 0)

        self.group_spin = Gtk.SpinButton()
        self.group_spin.set_range(0, 10)
        self.group_spin.set_increments(1, 1)
        self.group_spin.set_value(config.group)
        box.pack_start(self.group_spin, False, False, 0)

        # Transparency
        trans_label = Gtk.Label(label=f"Прозрачность: {int(config.transparency * 100)}%")
        trans_label.set_halign(Gtk.Align.START)
        box.pack_start(trans_label, False, False, 0)

        self.trans_scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 5)
        self.trans_scale.set_value(config.transparency * 100)
        self.trans_scale.connect("value-changed", lambda s: trans_label.set_text(
            f"Прозрачность: {int(s.get_value())}%"
        ))
        box.pack_start(self.trans_scale, False, False, 0)

        # Update interval
        interval_label = Gtk.Label(label="Интервал обновления (сек):")
        interval_label.set_halign(Gtk.Align.START)
        box.pack_start(interval_label, False, False, 0)

        self.interval_spin = Gtk.SpinButton()
        self.interval_spin.set_range(60, 3600)
        self.interval_spin.set_increments(60, 60)
        self.interval_spin.set_value(config.update_interval)
        box.pack_start(self.interval_spin, False, False, 0)

        self.show_all()

    def get_values(self):
        """Get settings values"""
        return {
            'backend_url': self.url_entry.get_text(),
            'group': int(self.group_spin.get_value()),
            'transparency': self.trans_scale.get_value() / 100,
            'update_interval': int(self.interval_spin.get_value())
        }


class TimetableWindow(Gtk.Window):
    """Main timetable window"""

    def __init__(self):
        super().__init__(title="ЧувГУ Расписание")

        self.config = Config()
        self.api = APIClient(self.config.backend_url)
        self.is_authenticated = False
        self.update_timer = None

        # Window setup
        self.set_default_size(*self.config.size)
        self.move(*self.config.position)
        self.set_decorated(False)  # Frameless
        self.set_keep_below(True)  # Keep below other windows
        self.stick()  # Show on all workspaces

        # Set transparency
        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual and screen.is_composited():
            self.set_visual(visual)
        self.set_opacity(self.config.transparency)

        # Enable dragging
        self.connect("button-press-event", self.on_button_press)
        self.connect("button-release-event", self.on_button_release)
        self.connect("motion-notify-event", self.on_mouse_move)
        self.dragging = False
        self.drag_offset = (0, 0)

        # Build UI
        self.build_ui()

        # Check auth status
        GLib.timeout_add(100, self.check_auth_status)

    def build_ui(self):
        """Build user interface"""
        # Main container
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        main_box.set_margin_start(15)
        main_box.set_margin_end(15)
        main_box.set_margin_top(15)
        main_box.set_margin_bottom(15)

        # Add rounded corners style
        css = b"""
        window {
            border-radius: 15px;
            background-color: rgba(30, 30, 30, 0.95);
            color: white;
        }
        """
        style_provider = Gtk.CssProvider()
        style_provider.load_from_data(css)
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            style_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        # Header
        self.header_label = Gtk.Label()
        self.header_label.set_markup("<b><big>Расписание</big></b>")
        main_box.pack_start(self.header_label, False, False, 0)

        # Day label
        self.day_label = Gtk.Label(label="Загрузка...")
        main_box.pack_start(self.day_label, False, False, 0)

        # Separator
        main_box.pack_start(Gtk.Separator(), False, False, 5)

        # Lessons scrolled window
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scrolled.set_min_content_height(300)

        self.lessons_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        scrolled.add(self.lessons_box)
        main_box.pack_start(scrolled, True, True, 0)

        # Separator
        main_box.pack_start(Gtk.Separator(), False, False, 5)

        # Status label
        self.status_label = Gtk.Label(label="Загрузка...")
        self.status_label.set_markup("<i><small>Загрузка...</small></i>")
        main_box.pack_start(self.status_label, False, False, 0)

        # Buttons
        button_box = Gtk.Box(spacing=10)

        self.login_button = Gtk.Button(label="Войти")
        self.login_button.connect("clicked", self.on_login_clicked)
        button_box.pack_start(self.login_button, True, True, 0)

        self.settings_button = Gtk.Button(label="Настройки")
        self.settings_button.connect("clicked", self.on_settings_clicked)
        button_box.pack_start(self.settings_button, True, True, 0)

        self.logout_button = Gtk.Button(label="Выйти")
        self.logout_button.connect("clicked", self.on_logout_clicked)
        self.logout_button.set_no_show_all(True)
        button_box.pack_start(self.logout_button, True, True, 0)

        main_box.pack_start(button_box, False, False, 0)

        self.add(main_box)
        self.show_all()

    def on_button_press(self, widget, event):
        """Handle mouse button press"""
        if event.button == 1:  # Left click
            self.dragging = True
            self.drag_offset = (event.x_root - self.get_position()[0],
                              event.y_root - self.get_position()[1])
        return False

    def on_button_release(self, widget, event):
        """Handle mouse button release"""
        if event.button == 1:
            self.dragging = False
            # Save position
            self.config.position = self.get_position()
        return False

    def on_mouse_move(self, widget, event):
        """Handle mouse movement"""
        if self.dragging:
            new_x = int(event.x_root - self.drag_offset[0])
            new_y = int(event.y_root - self.drag_offset[1])
            self.move(new_x, new_y)
        return False

    def check_auth_status(self):
        """Check authentication status"""
        try:
            is_auth, state = self.api.check_auth_status()
            self.is_authenticated = is_auth

            if is_auth:
                self.status_label.set_markup("<i><small>Подключено</small></i>")
                self.login_button.set_label("Обновить")
                self.logout_button.show()
                self.update_timetable()
                self.start_update_timer()
            else:
                self.status_label.set_markup("<i><small>Нажмите 'Войти'</small></i>")
                self.login_button.set_label("Войти")
                self.logout_button.hide()
        except Exception as e:
            self.status_label.set_markup(f"<i><small>Backend недоступен</small></i>")

        return False  # Don't repeat

    def on_login_clicked(self, button):
        """Handle login button click"""
        if self.is_authenticated:
            self.update_timetable()
        else:
            dialog = LoginDialog(self)
            response = dialog.run()

            if response == Gtk.ResponseType.OK:
                email, password = dialog.get_credentials()
                if email and password:
                    success, message = self.api.login(email, password)
                    if success:
                        dialog.destroy()
                        self.is_authenticated = True
                        self.status_label.set_markup("<i><small>Подключено</small></i>")
                        self.login_button.set_label("Обновить")
                        self.logout_button.show()
                        self.update_timetable()
                        self.start_update_timer()
                    else:
                        dialog.show_error(message)
                        return
                else:
                    dialog.show_error("Заполните все поля")
                    return

            dialog.destroy()

    def on_logout_clicked(self, button):
        """Handle logout button click"""
        self.api.logout()
        self.is_authenticated = False
        self.status_label.set_markup("<i><small>Вышли</small></i>")
        self.login_button.set_label("Войти")
        self.logout_button.hide()
        self.stop_update_timer()
        self.clear_lessons()

    def on_settings_clicked(self, button):
        """Handle settings button click"""
        dialog = SettingsDialog(self, self.config)
        response = dialog.run()

        if response == Gtk.ResponseType.OK:
            values = dialog.get_values()
            self.config.backend_url = values['backend_url']
            self.config.group = values['group']
            self.config.transparency = values['transparency']
            self.config.update_interval = values['update_interval']

            # Update API client
            self.api = APIClient(self.config.backend_url)

            # Update window transparency
            self.set_opacity(self.config.transparency)

            # Restart timer if authenticated
            if self.is_authenticated:
                self.start_update_timer()
                self.update_timetable()

        dialog.destroy()

    def update_timetable(self):
        """Update timetable data"""
        try:
            data = self.api.get_timetable(today=True)
            self.render_timetable(data)
        except Exception as e:
            self.status_label.set_markup(f"<i><small>Ошибка: {str(e)}</small></i>")

    def render_timetable(self, data):
        """Render timetable data"""
        self.clear_lessons()

        self.header_label.set_markup(f"<b><big>Расписание на {data.get('dayName', '')}</big></b>")
        self.day_label.set_text(data.get('weekDayName', ''))
        self.status_label.set_markup(f"<i><small>{data.get('state', 'OK')}</small></i>")

        items = data.get('items', [])
        if not items:
            empty_label = Gtk.Label(label="Нет занятий")
            empty_label.set_markup("<i>Нет занятий</i>")
            self.lessons_box.pack_start(empty_label, False, False, 0)
            self.lessons_box.show_all()
            return

        group_filter = self.config.group
        visible_count = 0

        for item in items:
            if visible_count >= 5:
                break

            if group_filter != 0 and item.get('subgroup', 0) != 0 and item.get('subgroup') != group_filter:
                continue

            lesson_frame = Gtk.Frame()
            lesson_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=3)
            lesson_box.set_margin_start(10)
            lesson_box.set_margin_end(10)
            lesson_box.set_margin_top(8)
            lesson_box.set_margin_bottom(8)

            # Discipline
            discipline_label = Gtk.Label()
            discipline_label.set_markup(f"<b>{item.get('discipline', '-')}</b>")
            discipline_label.set_halign(Gtk.Align.START)
            lesson_box.pack_start(discipline_label, False, False, 0)

            # Info
            info_text = f"{item.get('startTime', '')} - {item.get('endTime', '')}   {item.get('cabinet', '')}   {item.get('type', '')}"
            info_label = Gtk.Label(label=info_text)
            info_label.set_markup(f"<small>{info_text}</small>")
            info_label.set_halign(Gtk.Align.START)
            lesson_box.pack_start(info_label, False, False, 0)

            lesson_frame.add(lesson_box)
            self.lessons_box.pack_start(lesson_frame, False, False, 0)
            visible_count += 1

        if len(items) > 5:
            more_label = Gtk.Label()
            more_label.set_markup(f"<i><small>+ ещё {len(items) - 5} пар</small></i>")
            self.lessons_box.pack_start(more_label, False, False, 0)

        self.lessons_box.show_all()

    def clear_lessons(self):
        """Clear lessons display"""
        for child in self.lessons_box.get_children():
            self.lessons_box.remove(child)

    def start_update_timer(self):
        """Start auto-update timer"""
        self.stop_update_timer()
        self.update_timer = GLib.timeout_add_seconds(
            self.config.update_interval,
            self.on_timer_update
        )

    def stop_update_timer(self):
        """Stop auto-update timer"""
        if self.update_timer:
            GLib.source_remove(self.update_timer)
            self.update_timer = None

    def on_timer_update(self):
        """Handle timer update"""
        self.update_timetable()
        return True  # Continue timer
