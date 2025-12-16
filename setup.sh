#!/bin/bash

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_warning "Running as root. This is fine for initial setup."
    SUDO=""
else
    print_info "Running as non-root user. Will use sudo when needed."
    SUDO="sudo"
fi

print_info "=== Upload Test Server Setup Script ==="
echo ""

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_DIR="$SCRIPT_DIR"

print_info "Application directory: $APP_DIR"
echo ""

# Step 1: Update system
print_info "Step 1: Updating system packages..."
$SUDO apt update
$SUDO apt upgrade -y
print_success "System updated"
echo ""

# Step 2: Install Python and dependencies
print_info "Step 2: Installing Python and required packages..."
$SUDO apt install -y python3 python3-pip python3-venv wget curl
print_success "Python and dependencies installed"
echo ""

# Step 3: Create virtual environment
print_info "Step 3: Creating Python virtual environment..."
if [ ! -d "$APP_DIR/venv" ]; then
    python3 -m venv "$APP_DIR/venv"
    print_success "Virtual environment created"
else
    print_warning "Virtual environment already exists, skipping..."
fi
echo ""

# Step 4: Install Python dependencies
print_info "Step 4: Installing Python application dependencies..."
source "$APP_DIR/venv/bin/activate"
pip install --upgrade pip
pip install -r "$APP_DIR/requirements.txt"
print_success "Python dependencies installed"
echo ""

# Step 5: Create uploads directory
print_info "Step 5: Creating uploads directory..."
mkdir -p "$APP_DIR/uploads"
chmod 755 "$APP_DIR/uploads"
print_success "Uploads directory created"
echo ""

# Step 6: Setup systemd service
read -p "Do you want to set up the Flask app as a systemd service? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Step 6: Setting up systemd service..."

    # Get the username (non-root if available)
    if [ "$EUID" -eq 0 ]; then
        read -p "Enter the username to run the service as (default: ubuntu): " SERVICE_USER
        SERVICE_USER=${SERVICE_USER:-ubuntu}
    else
        SERVICE_USER=$(whoami)
    fi

    # Create systemd service file
    $SUDO tee /etc/systemd/system/upload-test.service > /dev/null <<EOF
[Unit]
Description=Upload Test Flask Server
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
WorkingDirectory=$APP_DIR
ExecStart=$APP_DIR/venv/bin/python $APP_DIR/server.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    $SUDO systemctl daemon-reload
    $SUDO systemctl enable upload-test.service
    $SUDO systemctl start upload-test.service

    print_success "Systemd service created and started"
    print_info "Service status:"
    $SUDO systemctl status upload-test.service --no-pager
else
    print_warning "Skipping systemd service setup"
fi
echo ""

# Step 7: Setup Cloudflare Tunnel
read -p "Do you want to set up Cloudflare Tunnel? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Step 7: Setting up Cloudflare Tunnel..."

    # Check if cloudflared is already installed
    if ! command -v cloudflared &> /dev/null; then
        print_info "Installing cloudflared..."

        # Detect architecture
        ARCH=$(uname -m)
        if [ "$ARCH" = "x86_64" ]; then
            CF_ARCH="amd64"
        elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
            CF_ARCH="arm64"
        else
            print_error "Unsupported architecture: $ARCH"
            exit 1
        fi

        wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${CF_ARCH}.deb
        $SUDO dpkg -i cloudflared-linux-${CF_ARCH}.deb
        rm cloudflared-linux-${CF_ARCH}.deb

        print_success "cloudflared installed"
    else
        print_warning "cloudflared already installed, skipping..."
    fi

    echo ""
    print_info "Cloudflare Tunnel Setup Instructions:"
    echo ""
    echo "1. Authenticate with Cloudflare:"
    echo "   cloudflared tunnel login"
    echo ""
    echo "2. Create a tunnel:"
    echo "   cloudflared tunnel create upload-test"
    echo ""
    echo "3. Create tunnel configuration at ~/.cloudflared/config.yml:"
    echo "   tunnel: <TUNNEL-ID>"
    echo "   credentials-file: /home/$(whoami)/.cloudflared/<TUNNEL-ID>.json"
    echo "   "
    echo "   ingress:"
    echo "     - hostname: upload-test.yourdomain.com"
    echo "       service: http://localhost:5000"
    echo "     - service: http_status:404"
    echo ""
    echo "4. Route DNS to your tunnel:"
    echo "   cloudflared tunnel route dns upload-test upload-test.yourdomain.com"
    echo ""
    echo "5. Install and run tunnel as a service:"
    echo "   sudo cloudflared service install"
    echo "   sudo systemctl enable cloudflared"
    echo "   sudo systemctl start cloudflared"
    echo ""

    read -p "Press Enter to continue..."
else
    print_warning "Skipping Cloudflare Tunnel setup"
fi
echo ""

# Step 8: Display final information
print_success "=== Setup Complete! ==="
echo ""
print_info "Application Details:"
echo "  - Location: $APP_DIR"
echo "  - Uploads directory: $APP_DIR/uploads"
echo "  - Virtual environment: $APP_DIR/venv"
echo ""

if $SUDO systemctl is-active --quiet upload-test.service 2>/dev/null; then
    print_info "Server Status: Running as systemd service"
    echo "  - Start: sudo systemctl start upload-test"
    echo "  - Stop: sudo systemctl stop upload-test"
    echo "  - Status: sudo systemctl status upload-test"
    echo "  - Logs: sudo journalctl -u upload-test -f"
else
    print_info "To manually start the server:"
    echo "  cd $APP_DIR"
    echo "  source venv/bin/activate"
    echo "  python server.py"
fi
echo ""

print_info "Access the application:"
echo "  - Local: http://localhost:5000"
if command -v cloudflared &> /dev/null; then
    echo "  - Via Cloudflare Tunnel: Configure as shown above"
fi
echo ""

print_success "All done! Happy testing!"
