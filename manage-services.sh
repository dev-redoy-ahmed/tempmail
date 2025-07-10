#!/bin/bash

# TempMail Services Management Script
# Provides easy commands for managing Haraka and MailAPI services

SERVICES=("haraka" "mailapi")
COLOR_GREEN="\033[0;32m"
COLOR_RED="\033[0;31m"
COLOR_YELLOW="\033[1;33m"
COLOR_BLUE="\033[0;34m"
COLOR_NC="\033[0m" # No Color

show_usage() {
    echo -e "${COLOR_BLUE}TempMail Services Manager${COLOR_NC}"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start     - Start all services"
    echo "  stop      - Stop all services"
    echo "  restart   - Restart all services"
    echo "  status    - Show service status"
    echo "  logs      - Show recent logs"
    echo "  follow    - Follow logs in real-time"
    echo "  enable    - Enable auto-start on boot"
    echo "  disable   - Disable auto-start on boot"
    echo "  health    - Quick health check"
    echo "  update    - Update services from git"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 logs"
    echo "  $0 follow"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${COLOR_RED}❌ This command requires root privileges (use sudo)${COLOR_NC}"
        exit 1
    fi
}

start_services() {
    check_root
    echo -e "${COLOR_BLUE}▶️  Starting TempMail services...${COLOR_NC}"
    for service in "${SERVICES[@]}"; do
        echo -n "Starting $service... "
        if systemctl start "$service"; then
            echo -e "${COLOR_GREEN}✅${COLOR_NC}"
        else
            echo -e "${COLOR_RED}❌${COLOR_NC}"
        fi
    done
}

stop_services() {
    check_root
    echo -e "${COLOR_BLUE}⏹️  Stopping TempMail services...${COLOR_NC}"
    for service in "${SERVICES[@]}"; do
        echo -n "Stopping $service... "
        if systemctl stop "$service"; then
            echo -e "${COLOR_GREEN}✅${COLOR_NC}"
        else
            echo -e "${COLOR_RED}❌${COLOR_NC}"
        fi
    done
}

restart_services() {
    check_root
    echo -e "${COLOR_BLUE}🔄 Restarting TempMail services...${COLOR_NC}"
    for service in "${SERVICES[@]}"; do
        echo -n "Restarting $service... "
        if systemctl restart "$service"; then
            echo -e "${COLOR_GREEN}✅${COLOR_NC}"
        else
            echo -e "${COLOR_RED}❌${COLOR_NC}"
        fi
    done
}

show_status() {
    echo -e "${COLOR_BLUE}📊 TempMail Services Status${COLOR_NC}"
    echo "=============================="
    for service in "${SERVICES[@]}"; do
        echo -e "\n${COLOR_YELLOW}$service:${COLOR_NC}"
        systemctl status "$service" --no-pager -l
    done
}

show_logs() {
    echo -e "${COLOR_BLUE}📋 Recent Logs (last 50 lines)${COLOR_NC}"
    echo "================================"
    for service in "${SERVICES[@]}"; do
        echo -e "\n${COLOR_YELLOW}=== $service logs ===${COLOR_NC}"
        journalctl -u "$service" -n 50 --no-pager
    done
}

follow_logs() {
    echo -e "${COLOR_BLUE}📋 Following logs in real-time (Ctrl+C to exit)${COLOR_NC}"
    echo "================================================"
    journalctl -u haraka -u mailapi -f
}

enable_services() {
    check_root
    echo -e "${COLOR_BLUE}🔧 Enabling auto-start on boot...${COLOR_NC}"
    for service in "${SERVICES[@]}"; do
        echo -n "Enabling $service... "
        if systemctl enable "$service"; then
            echo -e "${COLOR_GREEN}✅${COLOR_NC}"
        else
            echo -e "${COLOR_RED}❌${COLOR_NC}"
        fi
    done
}

disable_services() {
    check_root
    echo -e "${COLOR_BLUE}🔧 Disabling auto-start on boot...${COLOR_NC}"
    for service in "${SERVICES[@]}"; do
        echo -n "Disabling $service... "
        if systemctl disable "$service"; then
            echo -e "${COLOR_GREEN}✅${COLOR_NC}"
        else
            echo -e "${COLOR_RED}❌${COLOR_NC}"
        fi
    done
}

health_check() {
    echo -e "${COLOR_BLUE}🏥 Health Check${COLOR_NC}"
    echo "==============="
    for service in "${SERVICES[@]}"; do
        status=$(systemctl is-active "$service")
        enabled=$(systemctl is-enabled "$service")
        
        if [[ "$status" == "active" ]]; then
            status_icon="${COLOR_GREEN}✅${COLOR_NC}"
        else
            status_icon="${COLOR_RED}❌${COLOR_NC}"
        fi
        
        if [[ "$enabled" == "enabled" ]]; then
            enabled_icon="${COLOR_GREEN}✅${COLOR_NC}"
        else
            enabled_icon="${COLOR_YELLOW}⚠️${COLOR_NC}"
        fi
        
        echo -e "$service: $status_icon $status | Auto-start: $enabled_icon $enabled"
    done
}

update_services() {
    check_root
    echo -e "${COLOR_BLUE}🔄 Updating TempMail services...${COLOR_NC}"
    
    # Stop services
    echo "Stopping services..."
    systemctl stop haraka mailapi
    
    # Update from git
    echo "Pulling latest changes..."
    git pull origin main
    
    # Copy files
    echo "Copying application files..."
    cp -r haraka/* /opt/tempmail/haraka/
    cp -r mailapi/* /opt/tempmail/mailapi/
    
    # Update dependencies
    echo "Updating dependencies..."
    cd /opt/tempmail/haraka && npm install --production
    cd /opt/tempmail/mailapi && npm install --production
    
    # Fix permissions
    echo "Setting permissions..."
    chown -R haraka:haraka /opt/tempmail/haraka
    chown -R mailapi:mailapi /opt/tempmail/mailapi
    
    # Start services
    echo "Starting services..."
    systemctl start haraka mailapi
    
    echo -e "${COLOR_GREEN}✅ Update completed!${COLOR_NC}"
}

# Main script logic
case "$1" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    follow)
        follow_logs
        ;;
    enable)
        enable_services
        ;;
    disable)
        disable_services
        ;;
    health)
        health_check
        ;;
    update)
        update_services
        ;;
    *)
        show_usage
        exit 1
        ;;
esac