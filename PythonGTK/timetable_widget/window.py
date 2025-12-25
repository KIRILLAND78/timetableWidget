"""Main window for TimetableWidget"""

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib

from .api_client import APIClient
from .config import Config


class TimetableWindow(Gtk.Window):
    """Main timetable window - companion app"""

    def __init__(self):
        super().__init__(title="ЧувГУ Расписание")

        self.config = Config()
        self.api = APIClient(self.config.backend_url)
        self.is_authenticated = False
        self.update_timer = None
        self.update_interval = 5  # Fixed: 5 seconds

        # Window setup
        self.set_default_size(*self.config.size)
        self.move(*self.config.position)
        self.set_decorated(False)  # Frameless
        self.set_keep_below(True)  # Keep below other windows
        self.stick()  # Show on all workspaces

        # Hide from taskbar - make it a companion app
        self.set_type_hint(Gdk.WindowTypeHint.DOCK)
        self.set_skip_taskbar_hint(True)
        self.set_skip_pager_hint(True)

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

        # Check auth status and start auto-update
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
                self.status_label.set_markup("<i><small>Подключено • Обновление каждые 5 сек</small></i>")
                self.update_timetable()
                self.start_update_timer()
            else:
                self.status_label.set_markup("<i><small>Ожидание авторизации через бэкенд...</small></i>")
                # Retry auth check in 10 seconds
                GLib.timeout_add_seconds(10, self.check_auth_status)
        except Exception as e:
            self.status_label.set_markup(f"<i><small>Backend недоступен • Повтор через 10 сек</small></i>")
            # Retry connection in 10 seconds
            GLib.timeout_add_seconds(10, self.check_auth_status)

        return False  # Don't repeat

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
        """Start auto-update timer (every 5 seconds)"""
        self.stop_update_timer()
        self.update_timer = GLib.timeout_add_seconds(
            self.update_interval,  # 5 seconds
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
