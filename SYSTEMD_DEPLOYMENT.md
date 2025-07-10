# SystemD Service Deployment Guide

This guide explains how to deploy Haraka and MailAPI as systemd services for production use.

## 🎯 Benefits of SystemD Services

- ✅ **Automatic startup** on system boot
- ✅ **Automatic restart** if services crash
- ✅ **Background operation** (no terminal dependency)
- ✅ **Centralized logging** via journald
- ✅ **Resource management** and security isolation
- ✅ **Easy service management** with systemctl commands

## 📋 Prerequisites

- Linux system with systemd (Ubuntu 16.04+, CentOS 7+, etc.)
- Root/sudo access
- Node.js installed system-wide
- Git (for cloning the repository)

## 🚀 Quick Deployment

### Option 1: Automated Deployment (Recommended)

```bash
# Clone the repository
git clone https://github.com/dev-redoy-ahmed/tempmail.git
cd tempmail

# Make deployment script executable
chmod +x deploy-services.sh

# Run deployment script
sudo ./deploy-services.sh
```

### Option 2: Manual Deployment

#### Step 1: Create System Users

```bash
sudo useradd --system --no-create-home --shell /bin/false haraka
sudo useradd --system --no-create-home --shell /bin/false mailapi
```

#### Step 2: Create Directories

```bash
sudo mkdir -p /opt/tempmail/{haraka,mailapi}
sudo mkdir -p /opt/tempmail/haraka/{logs,queue}
sudo mkdir -p /opt/tempmail/mailapi/logs
```

#### Step 3: Copy Application Files

```bash
sudo cp -r haraka/* /opt/tempmail/haraka/
sudo cp -r mailapi/* /opt/tempmail/mailapi/
```

#### Step 4: Install Dependencies

```bash
cd /opt/tempmail/haraka && sudo npm install --production
cd /opt/tempmail/mailapi && sudo npm install --production
```

#### Step 5: Set Permissions

```bash
sudo chown -R haraka:haraka /opt/tempmail/haraka
sudo chown -R mailapi:mailapi /opt/tempmail/mailapi
sudo chmod -R 755 /opt/tempmail
```

#### Step 6: Install SystemD Services

```bash
sudo cp haraka.service /etc/systemd/system/
sudo cp mailapi.service /etc/systemd/system/
sudo systemctl daemon-reload
```

#### Step 7: Enable and Start Services

```bash
sudo systemctl enable haraka.service mailapi.service
sudo systemctl start haraka.service mailapi.service
```

## 🔧 Service Management

### Basic Commands

```bash
# Start services
sudo systemctl start haraka mailapi

# Stop services
sudo systemctl stop haraka mailapi

# Restart services
sudo systemctl restart haraka mailapi

# Check status
sudo systemctl status haraka mailapi

# Enable auto-start on boot
sudo systemctl enable haraka mailapi

# Disable auto-start
sudo systemctl disable haraka mailapi
```

### Viewing Logs

```bash
# View Haraka logs (real-time)
sudo journalctl -u haraka -f

# View MailAPI logs (real-time)
sudo journalctl -u mailapi -f

# View logs from last boot
sudo journalctl -u haraka --since "today"
sudo journalctl -u mailapi --since "today"

# View last 100 log entries
sudo journalctl -u haraka -n 100
sudo journalctl -u mailapi -n 100
```

## 📁 File Structure

```
/opt/tempmail/
├── haraka/
│   ├── config/
│   ├── plugins/
│   ├── logs/          # Service logs
│   ├── queue/         # Email queue
│   ├── haraka.js
│   └── package.json
└── mailapi/
    ├── logs/          # Service logs
    ├── public/
    ├── index.js
    └── package.json

/etc/systemd/system/
├── haraka.service
└── mailapi.service
```

## 🔒 Security Features

The systemd services include several security hardening features:

- **Dedicated users**: Services run as non-privileged system users
- **File system isolation**: `ProtectSystem=strict` and `ProtectHome=true`
- **Temporary file isolation**: `PrivateTmp=true`
- **No privilege escalation**: `NoNewPrivileges=true`
- **Limited file access**: Only specific directories are writable

## 🔧 Configuration

### Environment Variables

Edit the service files to modify environment variables:

```bash
sudo nano /etc/systemd/system/haraka.service
sudo nano /etc/systemd/system/mailapi.service
```

After editing, reload and restart:

```bash
sudo systemctl daemon-reload
sudo systemctl restart haraka mailapi
```

### Port Configuration

- **Haraka SMTP**: Port 25 (default SMTP)
- **MailAPI HTTP**: Port 3000 (configurable via PORT environment variable)

## 🚨 Troubleshooting

### Service Won't Start

```bash
# Check service status
sudo systemctl status haraka
sudo systemctl status mailapi

# Check detailed logs
sudo journalctl -u haraka --since "1 hour ago"
sudo journalctl -u mailapi --since "1 hour ago"
```

### Common Issues

1. **Permission denied**: Check file ownership and permissions
2. **Port already in use**: Check if other services are using the same ports
3. **Node.js not found**: Ensure Node.js is installed system-wide
4. **Missing dependencies**: Run `npm install` in service directories

### Reset Services

```bash
# Stop services
sudo systemctl stop haraka mailapi

# Remove service files
sudo rm /etc/systemd/system/haraka.service
sudo rm /etc/systemd/system/mailapi.service

# Reload systemd
sudo systemctl daemon-reload

# Remove application files (optional)
sudo rm -rf /opt/tempmail
```

## 📊 Monitoring

### Service Health Check

```bash
# Quick health check
sudo systemctl is-active haraka mailapi

# Detailed status
sudo systemctl status haraka mailapi --no-pager
```

### Log Monitoring

```bash
# Monitor both services simultaneously
sudo journalctl -u haraka -u mailapi -f

# Filter by log level
sudo journalctl -u haraka -p err
sudo journalctl -u mailapi -p warning
```

## 🔄 Updates

To update the services:

```bash
# Stop services
sudo systemctl stop haraka mailapi

# Update code
git pull origin main

# Copy new files
sudo cp -r haraka/* /opt/tempmail/haraka/
sudo cp -r mailapi/* /opt/tempmail/mailapi/

# Update dependencies
cd /opt/tempmail/haraka && sudo npm install --production
cd /opt/tempmail/mailapi && sudo npm install --production

# Fix permissions
sudo chown -R haraka:haraka /opt/tempmail/haraka
sudo chown -R mailapi:mailapi /opt/tempmail/mailapi

# Start services
sudo systemctl start haraka mailapi
```

## 🎉 Success!

Your TempMail services are now running as proper system services with:

- ✅ Automatic startup on boot
- ✅ Automatic restart on failure
- ✅ Centralized logging
- ✅ Security isolation
- ✅ Easy management via systemctl

The services will continue running even after you log out or reboot the system!