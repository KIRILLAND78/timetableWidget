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

# First, try to check if system packages are available (preferred method)
SYSTEM_PACKAGES_OK=false

if command -v dpkg &> /dev/null; then
    # Debian/Ubuntu system
    echo "Checking for system packages (Debian/Ubuntu)..."
    if dpkg -l | grep -q python3-gi && dpkg -l | grep -q python3-requests; then
        echo "✅ System packages already installed"
        SYSTEM_PACKAGES_OK=true
    else
        echo "📥 Installing via system package manager..."
        echo "Run: sudo apt install python3-gi python3-gi-cairo gir1.2-gtk-3.0 python3-requests"
        sudo apt install -y python3-gi python3-gi-cairo gir1.2-gtk-3.0 python3-requests 2>/dev/null
        if [ $? -eq 0 ]; then
            SYSTEM_PACKAGES_OK=true
        fi
    fi
elif command -v rpm &> /dev/null; then
    # Fedora/RHEL system
    echo "Checking for system packages (Fedora/RHEL)..."
    if rpm -q python3-gobject python3-requests &> /dev/null; then
        echo "✅ System packages already installed"
        SYSTEM_PACKAGES_OK=true
    else
        echo "📥 Installing via system package manager..."
        echo "Run: sudo dnf install python3-gobject gtk3 python3-requests"
        sudo dnf install -y python3-gobject gtk3 python3-requests 2>/dev/null
        if [ $? -eq 0 ]; then
            SYSTEM_PACKAGES_OK=true
        fi
    fi
fi

# If system packages didn't work, try pip with virtual environment
if [ "$SYSTEM_PACKAGES_OK" = false ]; then
    echo "⚠️  System packages not available or installation failed"
    echo "Creating virtual environment for Python dependencies..."

    # Create venv if it doesn't exist
    if [ ! -d "venv" ]; then
        python3 -m venv venv
        if [ $? -ne 0 ]; then
            echo "❌ Failed to create virtual environment"
            echo "Please install system packages manually:"
            echo "  Debian/Ubuntu: sudo apt install python3-gi python3-gi-cairo gir1.2-gtk-3.0 python3-requests"
            echo "  Fedora/RHEL: sudo dnf install python3-gobject gtk3 python3-requests"
            exit 1
        fi
    fi

    # Activate venv and install dependencies
    source venv/bin/activate
    pip install -r requirements.txt

    if [ $? -ne 0 ]; then
        echo "❌ Failed to install dependencies in virtual environment"
        echo "Please install system packages manually:"
        echo "  Debian/Ubuntu: sudo apt install python3-gi python3-gi-cairo gir1.2-gtk-3.0 python3-requests"
        echo "  Fedora/RHEL: sudo dnf install python3-gobject gtk3 python3-requests"
        exit 1
    fi

    deactivate
    echo "✅ Dependencies installed in virtual environment"
    USE_VENV=true
else
    USE_VENV=false
fi

# Install application
echo "📋 Installing application..."

# Copy main script
sudo mkdir -p /usr/local/lib/timetable-widget
sudo cp -r timetable_widget /usr/local/lib/timetable-widget/
sudo cp main.py /usr/local/lib/timetable-widget/

# Create launcher script
if [ "$USE_VENV" = true ]; then
    # Copy venv to installation directory
    sudo cp -r venv /usr/local/lib/timetable-widget/

    sudo tee /usr/local/bin/timetable-widget > /dev/null <<'EOF'
#!/bin/bash
cd /usr/local/lib/timetable-widget
if [ -d "venv" ]; then
    source venv/bin/activate
fi
exec python3 main.py "$@"
EOF
else
    sudo tee /usr/local/bin/timetable-widget > /dev/null <<'EOF'
#!/bin/bash
cd /usr/local/lib/timetable-widget
exec python3 main.py "$@"
EOF
fi

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
if [ "$USE_VENV" = true ]; then
    echo "📦 Python dependencies installed using virtual environment"
else
    echo "📦 Python dependencies installed using system packages"
fi
echo ""
echo "📝 Next steps:"
echo "1. Start the backend: cd TimetableWidget.Backend && dotnet run"
echo "2. Launch the widget:"
echo "   - From terminal: timetable-widget"
echo "   - From app menu: Search for 'ЧувГУ Расписание'"
echo "   - Add to startup: Copy timetable-widget.desktop to ~/.config/autostart/"
echo ""
echo "🔄 To update: Run this script again"
echo "🗑️  To uninstall:"
echo "  sudo rm -rf /usr/local/lib/timetable-widget"
echo "  sudo rm /usr/local/bin/timetable-widget"
echo "  rm ~/.local/share/applications/timetable-widget.desktop"
