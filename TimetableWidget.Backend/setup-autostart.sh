#!/bin/bash

# Setup autostart for TimetableWidget Backend
# This script configures the backend to start automatically on login

echo "🚀 Setting up TimetableWidget Backend autostart..."

# Get the absolute path to the backend directory
BACKEND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Backend directory: $BACKEND_DIR"

# Check if backend executable exists
BACKEND_EXE="$BACKEND_DIR/TimetableWidget.Backend"
if [ ! -f "$BACKEND_EXE" ]; then
    echo "❌ Error: Backend executable not found at: $BACKEND_EXE"
    echo "Please make sure TimetableWidget.Backend file exists in this directory"
    exit 1
fi

# Make sure it's executable
chmod +x "$BACKEND_EXE"
echo "✅ Backend executable found and is executable"

# Create autostart directory
AUTOSTART_DIR="$HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"

# Create .desktop file for autostart
DESKTOP_FILE="$AUTOSTART_DIR/timetable-backend.desktop"

cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=TimetableWidget Backend
Comment=ChuvSU Timetable Widget Backend API
Exec=$BACKEND_EXE
Path=$BACKEND_DIR
Terminal=false
StartupNotify=false
X-GNOME-Autostart-enabled=true
Hidden=false
EOF

chmod +x "$DESKTOP_FILE"

echo "✅ Autostart configured successfully!"
echo ""
echo "📝 Backend will start automatically on next login"
echo ""
echo "🎯 To start backend now:"
echo "   $BACKEND_EXE"
echo ""
echo "🔧 To disable autostart:"
echo "   rm $DESKTOP_FILE"
echo ""
echo "📊 To check if backend is running:"
echo "   curl http://localhost:5678/"
echo ""
echo "📋 To view running backend processes:"
echo "   ps aux | grep TimetableWidget.Backend"
