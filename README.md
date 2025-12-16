# Upload Speed Test via Cloudflare Tunnel

A simple web application to test file upload speeds through a Cloudflare tunnel. Features a clean UI and tracks upload times, speeds, and file sizes.

## Features

- Drag-and-drop file upload interface
- Multiple file upload support
- Real-time upload progress
- Upload speed calculation (Mbps)
- Timestamped file storage
- Upload statistics endpoint

## Quick Setup (Recommended)

For a fresh Ubuntu LXD instance, simply run:

```bash
./quick-setup.sh
```

This will:
- Install Python and all dependencies
- Create a virtual environment
- Set up the uploads directory
- Optionally install as a systemd service

Then access at `http://localhost:5000` or through your Cloudflare tunnel.

## Prerequisites

- Python 3.8 or higher
- pip (Python package manager)
- Cloudflare account (for tunnel setup)
- LXD instance (for deployment)

## Manual Setup

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Run the server:
```bash
python server.py
```

3. Access the UI at `http://localhost:5000`

## LXD Instance Setup

1. Create and launch an LXD container:
```bash
lxc launch ubuntu:22.04 upload-test
lxc exec upload-test -- bash
```

2. Inside the container, install Python and dependencies:
```bash
apt update
apt install -y python3 python3-pip
```

3. Copy the project files to the container:
```bash
# From host
lxc file push -r /path/to/Test-Upload-Times upload-test/home/ubuntu/
```

4. Inside the container, install Python dependencies:
```bash
cd /home/ubuntu/Test-Upload-Times
pip3 install -r requirements.txt
```

5. Run the server:
```bash
python3 server.py
```

## Cloudflare Tunnel Setup

1. Install cloudflared in your LXD container:
```bash
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
dpkg -i cloudflared-linux-amd64.deb
```

2. Authenticate with Cloudflare:
```bash
cloudflared tunnel login
```

3. Create a tunnel:
```bash
cloudflared tunnel create upload-test
```

4. Configure the tunnel (create config.yml):
```yaml
tunnel: <TUNNEL-ID>
credentials-file: /root/.cloudflared/<TUNNEL-ID>.json

ingress:
  - hostname: upload-test.yourdomain.com
    service: http://localhost:5000
  - service: http_status:404
```

5. Route DNS to your tunnel:
```bash
cloudflared tunnel route dns upload-test upload-test.yourdomain.com
```

6. Run the tunnel:
```bash
cloudflared tunnel run upload-test
```

## Running as a Service

Create a systemd service for the Flask app:

```bash
cat > /etc/systemd/system/upload-test.service <<EOF
[Unit]
Description=Upload Test Flask Server
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/Test-Upload-Times
ExecStart=/usr/bin/python3 /home/ubuntu/Test-Upload-Times/server.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl enable upload-test
systemctl start upload-test
```

Create a systemd service for Cloudflare tunnel:

```bash
cloudflared service install
systemctl enable cloudflared
systemctl start cloudflared
```

## API Endpoints

### POST /upload
Upload one or more files

**Request:**
- Method: POST
- Content-Type: multipart/form-data
- Body: files (file array)

**Response:**
```json
{
  "success": true,
  "files": [
    {
      "filename": "20241216_123456_example.txt",
      "size": 1024
    }
  ],
  "upload_time": 0.52,
  "count": 1
}
```

### GET /stats
Get upload statistics

**Response:**
```json
{
  "file_count": 10,
  "total_size": 10485760,
  "total_size_mb": 10.0
}
```

## File Storage

- Uploaded files are stored in the `uploads/` directory
- Files are automatically prefixed with a timestamp
- Maximum file size: 16GB

## Security Notes

For production use, consider:
- Adding authentication
- Implementing rate limiting
- Adding file type validation
- Setting up HTTPS
- Configuring firewall rules
- Regular cleanup of uploads directory

## License

MIT
# Test-Cloudflare-Upload-Speeds
