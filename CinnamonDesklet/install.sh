#!/bin/bash

# Installation script for TimetableWidget Cinnamon Desklet

DESKLET_NAME="timetable@chuvsu"
INSTALL_DIR="$HOME/.local/share/cinnamon/desklets"
SOURCE_DIR="$(dirname "$0")/timetable@chuvsu/files/timetable@chuvsu"

echo "🚀 Installing TimetableWidget Cinnamon Desklet..."

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ Error: Source directory not found: $SOURCE_DIR"
    exit 1
fi

# Create desklets directory if it doesn't exist
if [ ! -d "$INSTALL_DIR" ]; then
    echo "📁 Creating desklets directory..."
    mkdir -p "$INSTALL_DIR"
fi

# Remove old version if exists
if [ -d "$INSTALL_DIR/$DESKLET_NAME" ]; then
    echo "🗑️  Removing old version..."
    rm -rf "$INSTALL_DIR/$DESKLET_NAME"
fi

# Copy desklet files
echo "📋 Copying desklet files..."
cp -r "$SOURCE_DIR" "$INSTALL_DIR/"

if [ $? -eq 0 ]; then
    echo "✅ Installation completed successfully!"
    echo ""
    echo "📝 Next steps:"
    echo "1. Start the backend: cd TimetableWidget.Backend && dotnet run"
    echo "2. Right-click on desktop → 'Add Desklets'"
    echo "3. Find 'ЧувГУ Расписание' and click '+'"
    echo "4. Click on the desklet to login"
    echo ""
    echo "🔧 To configure: Right-click on desklet → 'Configure...'"
else
    echo "❌ Installation failed!"
    exit 1
fi
