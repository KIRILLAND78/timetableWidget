#!/bin/bash

# Installation script for TimetableWidget Python GTK Application

echo "🚀 Installing TimetableWidget Python GTK Application..."

# Check Python version
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
REQUIRED_VERSION="3.7"

if ! python3 -c "import sys; exit(0 if sys.version_info >= (3, 7) else 1)"; then
    echo "❌ Error: Python 3.7 or higher is required"
    echo "Current version: $PYTHON_VERSION"
    exit 1
fi

echo "✅ Python version: $PYTHON_VERSION"

# Install Python dependencies
echo "📦 Installing Python dependencies..."

if command -v pip3 &> /dev/null; then
    pip3 install --user -r requirements.txt
elif command -v pip &> /dev/null; then
    pip install --user -r requirements.txt
else
    echo "❌ Error: pip not found. Please install python3-pip"
    exit 1
fi

if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    echo "Try installing manually:"
    echo "  sudo apt install python3-gi python3-gi-cairo gir1.2-gtk-3.0 python3-requests"
    echo "  Or: sudo dnf install python3-gobject gtk3 python3-requests"
    exit 1
fi

# Install application
echo "📋 Installing application..."

# Copy main script
sudo mkdir -p /usr/local/lib/timetable-widget
sudo cp -r timetable_widget /usr/local/lib/timetable-widget/
sudo cp main.py /usr/local/lib/timetable-widget/

# Create launcher script
sudo tee /usr/local/bin/timetable-widget > /dev/null <<'EOF'
#!/bin/bash
cd /usr/local/lib/timetable-widget
exec python3 main.py "$@"
EOF

sudo chmod +x /usr/local/bin/timetable-widget

# Install desktop entry
DESKTOP_DIR="$HOME/.local/share/applications"
mkdir -p "$DESKTOP_DIR"
sed "s|/usr/local/bin/timetable-widget|timetable-widget|g" timetable-widget.desktop > "$DESKTOP_DIR/timetable-widget.desktop"
chmod +x "$DESKTOP_DIR/timetable-widget.desktop"

# Update desktop database
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database "$DESKTOP_DIR" 2>/dev/null
fi

echo "✅ Installation completed successfully!"
echo ""
echo "📝 Next steps:"
echo "1. Start the backend: cd TimetableWidget.Backend && dotnet run"
echo "2. Launch the widget:"
echo "   - From terminal: timetable-widget"
echo "   - From app menu: Search for 'ЧувГУ Расписание'"
echo "   - Add to startup: Copy timetable-widget.desktop to ~/.config/autostart/"
echo "3. Click 'Войти' to login with ChuvSU credentials"
echo "4. Click 'Настройки' to configure"
echo ""
echo "🔄 To update: Run this script again"
echo "🗑️  To uninstall:"
echo "  sudo rm -rf /usr/local/lib/timetable-widget"
echo "  sudo rm /usr/local/bin/timetable-widget"
echo "  rm ~/.local/share/applications/timetable-widget.desktop"
