#!/bin/bash

# Installation script for TimetableWidget GNOME Shell Extension

EXTENSION_UUID="timetable@chuvsu.extensions.gnome.org"
SOURCE_DIR="$(dirname "$0")/$EXTENSION_UUID"
INSTALL_DIR="$HOME/.local/share/gnome-shell/extensions"

echo "🚀 Installing TimetableWidget GNOME Shell Extension..."

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ Error: Source directory not found: $SOURCE_DIR"
    exit 1
fi

# Create extensions directory if it doesn't exist
if [ ! -d "$INSTALL_DIR" ]; then
    echo "📁 Creating extensions directory..."
    mkdir -p "$INSTALL_DIR"
fi

# Remove old version if exists
if [ -d "$INSTALL_DIR/$EXTENSION_UUID" ]; then
    echo "🗑️  Removing old version..."
    rm -rf "$INSTALL_DIR/$EXTENSION_UUID"
fi

# Copy extension files
echo "📋 Copying extension files..."
cp -r "$SOURCE_DIR" "$INSTALL_DIR/"

# Compile GSettings schema
echo "⚙️  Compiling GSettings schema..."
if [ -d "$INSTALL_DIR/$EXTENSION_UUID/schemas" ]; then
    glib-compile-schemas "$INSTALL_DIR/$EXTENSION_UUID/schemas/" 2>/dev/null || {
        echo "⚠️  Warning: Failed to compile schemas. Extension may not work properly."
    }
fi

if [ $? -eq 0 ]; then
    echo "✅ Installation completed successfully!"
    echo ""
    echo "📝 Next steps:"
    echo "1. Start the backend: cd TimetableWidget.Backend && dotnet run"
    echo "2. Restart GNOME Shell:"
    echo "   - X11: Press Alt+F2, type 'r', press Enter"
    echo "   - Wayland: Log out and log back in"
    echo "3. Enable extension:"
    echo "   gnome-extensions enable $EXTENSION_UUID"
    echo "   Or use GNOME Extensions app"
    echo "4. Click on panel icon to login"
    echo ""
    echo "🔧 To configure: gnome-extensions prefs $EXTENSION_UUID"
    echo ""
    echo "🔄 To update: Run this script again"
    echo "🗑️  To uninstall: gnome-extensions uninstall $EXTENSION_UUID"
else
    echo "❌ Installation failed!"
    exit 1
fi
