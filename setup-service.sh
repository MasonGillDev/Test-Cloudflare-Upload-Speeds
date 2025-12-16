#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root or with sudo"
    exit 1
fi

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_DIR="$SCRIPT_DIR"

print_info "Setting up systemd service for Upload Test Server..."

# Get username
read -p "Enter the username to run the service as (default: ubuntu): " SERVICE_USER
SERVICE_USER=${SERVICE_USER:-ubuntu}

# Verify user exists
if ! id "$SERVICE_USER" &>/dev/null; then
    echo "Error: User $SERVICE_USER does not exist"
    exit 1
fi

# Create systemd service file
tee /etc/systemd/system/upload-test.service > /dev/null <<EOF
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
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
systemctl daemon-reload

# Enable and start service
systemctl enable upload-test.service
systemctl start upload-test.service

print_success "Service created and started"
echo ""
print_info "Service commands:"
echo "  - Start:   sudo systemctl start upload-test"
echo "  - Stop:    sudo systemctl stop upload-test"
echo "  - Restart: sudo systemctl restart upload-test"
echo "  - Status:  sudo systemctl status upload-test"
echo "  - Logs:    sudo journalctl -u upload-test -f"
echo ""

# Show current status
print_info "Current service status:"
systemctl status upload-test.service --no-pager || true
