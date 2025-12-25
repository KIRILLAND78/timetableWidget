#!/bin/bash

# Installation script for TimetableWidget KDE Plasmoid

WIDGET_NAME="org.chuvsu.timetable"
SOURCE_DIR="$(dirname "$0")/$WIDGET_NAME"

echo "🚀 Installing TimetableWidget KDE Plasma Widget..."

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ Error: Source directory not found: $SOURCE_DIR"
    exit 1
fi

# Check if plasmapkg2 or kpackagetool5 is available
if command -v kpackagetool6 &> /dev/null; then
    PLASMAPKG="kpackagetool6"
elif command -v kpackagetool5 &> /dev/null; then
    PLASMAPKG="kpackagetool5"
elif command -v plasmapkg2 &> /dev/null; then
    PLASMAPKG="plasmapkg2"
else
    echo "❌ Error: No Plasma package tool found (kpackagetool6, kpackagetool5, or plasmapkg2)"
    echo "Please install KDE Plasma development tools"
    exit 1
fi

echo "📦 Using package tool: $PLASMAPKG"

# Remove old version if exists
echo "🗑️  Removing old version (if exists)..."
$PLASMAPKG --type Plasma/Applet --remove $WIDGET_NAME 2>/dev/null

# Install new version
echo "📋 Installing new version..."
$PLASMAPKG --type Plasma/Applet --install "$SOURCE_DIR"

if [ $? -eq 0 ]; then
    echo "✅ Installation completed successfully!"
    echo ""
    echo "📝 Next steps:"
    echo "1. Start the backend: cd TimetableWidget.Backend && dotnet run"
    echo "2. Right-click on desktop or panel → 'Add Widgets...'"
    echo "3. Search for 'ЧувГУ Расписание'"
    echo "4. Drag it to desktop or panel"
    echo "5. Click 'Войти' button to login"
    echo ""
    echo "🔧 To configure: Right-click on widget → 'Configure ЧувГУ Расписание...'"
    echo ""
    echo "🔄 To update: Run this script again"
    echo "🗑️  To uninstall: $PLASMAPKG --type Plasma/Applet --remove $WIDGET_NAME"
else
    echo "❌ Installation failed!"
    echo "Try updating instead:"
    echo "$PLASMAPKG --type Plasma/Applet --upgrade \"$SOURCE_DIR\""
    exit 1
fi
