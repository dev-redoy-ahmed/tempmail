#!/bin/bash

# TempMail Services Deployment Script
# This script sets up Haraka and MailAPI as systemd services

set -e

echo "🚀 Starting TempMail Services Deployment..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root (use sudo)"
   exit 1
fi

# Create system users for services
echo "👤 Creating system users..."
if ! id "haraka" &>/dev/null; then
    useradd --system --no-create-home --shell /bin/false haraka
    echo "✅ Created haraka user"
else
    echo "ℹ️  haraka user already exists"
fi

if ! id "mailapi" &>/dev/null; then
    useradd --system --no-create-home --shell /bin/false mailapi
    echo "✅ Created mailapi user"
else
    echo "ℹ️  mailapi user already exists"
fi

# Create application directories
echo "📁 Creating application directories..."
mkdir -p /opt/tempmail/{haraka,mailapi}
mkdir -p /opt/tempmail/haraka/{logs,queue}
mkdir -p /opt/tempmail/mailapi/logs

# Copy application files
echo "📋 Copying application files..."
cp -r haraka/* /opt/tempmail/haraka/
cp -r mailapi/* /opt/tempmail/mailapi/

# Install Node.js dependencies
echo "📦 Installing Node.js dependencies..."
cd /opt/tempmail/haraka && npm install --production
cd /opt/tempmail/mailapi && npm install --production

# Set proper ownership
echo "🔐 Setting file permissions..."
chown -R haraka:haraka /opt/tempmail/haraka
chown -R mailapi:mailapi /opt/tempmail/mailapi
chmod -R 755 /opt/tempmail
chmod -R 750 /opt/tempmail/haraka/logs
chmod -R 750 /opt/tempmail/mailapi/logs

# Copy systemd service files
echo "⚙️  Installing systemd services..."
cp haraka.service /etc/systemd/system/
cp mailapi.service /etc/systemd/system/

# Reload systemd and enable services
echo "🔄 Configuring systemd services..."
systemctl daemon-reload
systemctl enable haraka.service
systemctl enable mailapi.service

# Start services
echo "▶️  Starting services..."
systemctl start haraka.service
systemctl start mailapi.service

# Check service status
echo "📊 Service Status:"
echo "=================="
systemctl status haraka.service --no-pager -l
echo ""
systemctl status mailapi.service --no-pager -l

echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "📋 Service Management Commands:"
echo "  Start services:   sudo systemctl start haraka mailapi"
echo "  Stop services:    sudo systemctl stop haraka mailapi"
echo "  Restart services: sudo systemctl restart haraka mailapi"
echo "  Check status:     sudo systemctl status haraka mailapi"
echo "  View logs:        sudo journalctl -u haraka -f"
echo "                    sudo journalctl -u mailapi -f"
echo ""
echo "🌐 Services are now running and will auto-start on boot!"