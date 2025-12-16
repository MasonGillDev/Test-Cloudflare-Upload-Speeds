#!/bin/bash

set -e  # Exit on error

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

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

print_info "=== Quick Server Setup ==="
echo ""

# Update and install dependencies
print_info "Installing system dependencies..."
sudo apt update
sudo apt install -y python3 python3-pip python3-venv

# Create virtual environment
print_info "Creating virtual environment..."
python3 -m venv venv

# Install Python requirements
print_info "Installing Python packages..."
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Create uploads directory
print_info "Creating uploads directory..."
mkdir -p uploads

print_success "Setup complete!"
echo ""
print_info "To start the server manually:"
echo "  cd $SCRIPT_DIR"
echo "  source venv/bin/activate"
echo "  python server.py"
echo ""

# Ask about systemd service
read -p "Install as systemd service? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    SERVICE_USER=$(whoami)

    sudo tee /etc/systemd/system/upload-test.service > /dev/null <<EOF
[Unit]
Description=Upload Test Flask Server
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
WorkingDirectory=$SCRIPT_DIR
ExecStart=$SCRIPT_DIR/venv/bin/python $SCRIPT_DIR/server.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable upload-test.service
    sudo systemctl start upload-test.service

    print_success "Service installed and started!"
    echo ""
    print_info "Service commands:"
    echo "  sudo systemctl status upload-test"
    echo "  sudo systemctl stop upload-test"
    echo "  sudo systemctl restart upload-test"
    echo "  sudo journalctl -u upload-test -f"
fi

echo ""
print_success "All done! Server accessible at http://localhost:5000"
