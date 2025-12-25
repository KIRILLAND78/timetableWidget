#!/usr/bin/env python3
"""
TimetableWidget - ChuvSU Timetable Widget
Main entry point
"""

import sys
import gi

gi.require_version('Gtk', '3.0')
from gi.repository import Gtk

from timetable_widget.window import TimetableWindow


def main():
    """Main application entry point"""
    window = TimetableWindow()
    window.connect("destroy", Gtk.main_quit)
    window.show_all()
    Gtk.main()
    return 0


if __name__ == "__main__":
    sys.exit(main())
