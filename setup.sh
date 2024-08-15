#!/bin/bash

# Colors for visual appeal
GREEN="\\033[0;32m"
CYAN="\\033[0;36m"
RED="\\033[0;31m"
YELLOW="\\033[1;33m"
NC="\\033[0m" # No Color

# Function to display the header with ASCII art
display_header() {
    echo -e "${CYAN}"
    echo "###############################################"
    echo "#                                             #"
    echo "#      Bratwurst-ADSB Monitoring Script       #"
    echo "#                                             #"
    echo "###############################################"
    echo -e "${NC}"
}

# Function to list and select USB device
select_usb_device() {
    echo -e "${YELLOW}Available USB devices (should contain something like 'RTL2838', 'DVB-T' or similar):${NC}"
    lsusb | nl -w 2 -s '. '
    echo ""

    read -p "Enter the number corresponding to your SDR Stick: " DEVICE_NUMBER
    USB_DEVICE_ID=$(lsusb | sed -n "${DEVICE_NUMBER}p" | awk '{print $6}')

    if [ -z "$USB_DEVICE_ID" ]; then
        echo -e "${RED}Invalid selection. Please try again.${NC}"
        select_usb_device
    else
        echo -e "${GREEN}Selected USB Device ID: ${USB_DEVICE_ID}${NC}"
    fi
}

# Function to get Telegram Bot Token and Chat ID
get_telegram_bot_details() {
    echo -e "${YELLOW}To create a new Telegram bot, follow the guide at:${NC} ${CYAN}https://gist.github.com/nafiesl/4ad622f344cd1dc3bb1ecbe468ff9f8a${NC}"
    echo ""
    read -p "Enter your Telegram Bot Token: " TELEGRAM_BOT_TOKEN
    read -p "Enter your Telegram Chat ID: " TELEGRAM_CHAT_ID
}

# Function to generate the config.yaml from the sample
generate_config() {
    cp config.yaml.sample config.yaml
    sed -i "s|PLACEHOLDER_FOR_DEVICE_ID|$USB_DEVICE_ID|g" config.yaml
    sed -i "s|PLACEHOLDER_FOR_TELEGRAM_BOT_TOKEN|$TELEGRAM_BOT_TOKEN|g" config.yaml
    sed -i "s|PLACEHOLDER_FOR_TELEGRAM_CHAT_ID|$TELEGRAM_CHAT_ID|g" config.yaml
    echo -e "${GREEN}Configuration file 'config.yaml' created.${NC}"
}

# Function to copy files to correct paths (excluding bratwurst_monitor.sh)
copy_files() {
    SCRIPT_DIR=$(pwd)
    echo -e "${GREEN}Using current directory: $SCRIPT_DIR${NC}"

    # Ensure bratwurst_monitor.sh is executable
    sudo chmod +x "$SCRIPT_DIR/bratwurst_monitor.sh"
    sudo chmod +x "$SCRIPT_DIR/uninstall.sh"

    # Replace the placeholder path in the systemd service file
   sed -i "s|ExecStart=.*|ExecStart=$SCRIPT_DIR/bratwurst_monitor.sh|g" bratwurst_monitor.service

    # Copy systemd service and timer files
    sudo cp bratwurst_monitor.service /etc/systemd/system/
    sudo cp bratwurst_monitor.timer /etc/systemd/system/
}

# Function to enable and start the systemd service and timer
enable_and_start_service() {
    sudo systemctl daemon-reload
    sudo systemctl enable bratwurst_monitor.timer
    sudo systemctl start bratwurst_monitor.timer
    echo -e "${GREEN}System monitor has been successfully set up and is now running!${NC}"
}

# Send startup notification
send_startup_notification() {
    BOT_TOKEN=$(grep 'telegram_bot_token:' config.yaml | awk '{print $2}' | tr -d '"')
    CHAT_ID=$(grep 'telegram_chat_id:' config.yaml | awk '{print $2}' | tr -d '"')

    STARTUP_MESSAGE="🚀 Bratwurst-ADSB Monitoring Script has started successfully!"

    if [ ! -z "$BOT_TOKEN" ] && [ ! -z "$CHAT_ID" ]; then
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d text="$STARTUP_MESSAGE"
    fi
}

# Main script execution
display_header
select_usb_device
get_telegram_bot_details
generate_config
copy_files
enable_and_start_service
send_startup_notification

echo -e "${CYAN}Configuration complete!${NC}"
exit 0
