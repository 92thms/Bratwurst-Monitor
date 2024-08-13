#!/bin/bash

# Determine the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load configuration from config.yaml
CONFIG_FILE="$SCRIPT_DIR/config.yaml"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file '$CONFIG_FILE' not found. Exiting."
    exit 1
fi

DEVICE_ID=$(grep 'device_id:' $CONFIG_FILE | awk '{print $2}' | tr -d '"')
BOT_TOKEN=$(grep 'telegram_bot_token:' $CONFIG_FILE | awk '{print $2}' | tr -d '"')
CHAT_ID=$(grep 'telegram_chat_id:' $CONFIG_FILE | awk '{print $2}' | tr -d '"')

if [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
    echo "Error: Telegram Bot Token or Chat ID is missing in '$CONFIG_FILE'. Exiting."
    exit 1
fi

# Other constants
SERVICE_NAME="readsb.service" # Service to monitor (constant)
LAST_NOTIFICATION_FILE="/tmp/last_notification_time" # File to track the last notification time
LAST_STATUS_FILE="/tmp/last_service_status" # File to track the last known service status
STARTUP_NOTIFICATION_FILE="/tmp/bratwurst_monitor_startup" # File to ensure startup notification is sent only once

# Messages
DEVICE_MESSAGE="SDR Device is not detected. Please check the connection."
SERVICE_MESSAGE="READSB service is not running anymore. Please check it."
SERVICE_RECOVERED_MESSAGE="READSB service is running again!"
STARTUP_MESSAGE="Bratwurst-ADSB Monitoring Script has started successfully!"

# Send startup notification (always on start)
curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
-d chat_id="$CHAT_ID" \
-d text="$STARTUP_MESSAGE"

# Create or update the startup notification file
touch $STARTUP_NOTIFICATION_FILE

# Get the current time
CURRENT_TIME=$(date +%s)
LAST_NOTIFICATION_TIME=$(cat $LAST_NOTIFICATION_FILE 2>/dev/null || echo 0)
TIME_DIFF=$((CURRENT_TIME - LAST_NOTIFICATION_TIME))
LAST_STATUS=$(cat $LAST_STATUS_FILE 2>/dev/null || echo "unknown")

# Check USB Device
if ! lsusb | grep -q "$DEVICE_ID"; then
    if [ "$LAST_STATUS" != "hardware_down" ]; then
        # Send notification immediately if device goes down
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d text="$DEVICE_MESSAGE"
        echo $CURRENT_TIME > $LAST_NOTIFICATION_FILE
        echo "hardware_down" > $LAST_STATUS_FILE
    elif [ $TIME_DIFF -ge 86400 ]; then
        # Send reminder if device stays down for 24 hours
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d text="$DEVICE_MESSAGE"
        echo $CURRENT_TIME > $LAST_NOTIFICATION_FILE
    fi
else
    # Check Service Status
    if ! systemctl is-active --quiet $SERVICE_NAME; then
        if [ "$LAST_STATUS" != "service_down" ]; then
            # Send notification immediately if service goes down
            curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
            -d chat_id="$CHAT_ID" \
            -d text="$SERVICE_MESSAGE"
            echo $CURRENT_TIME > $LAST_NOTIFICATION_FILE
            echo "service_down" > $LAST_STATUS_FILE
        elif [ $TIME_DIFF -ge 86400 ]; then
            # Send reminder if service stays down for 24 hours
            curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
            -d chat_id="$CHAT_ID" \
            -d text="$SERVICE_MESSAGE"
            echo $CURRENT_TIME > $LAST_NOTIFICATION_FILE
        fi
    else
        # If the service is running and was previously marked as down, send a recovery message
        if [ "$LAST_STATUS" == "service_down" ] || [ "$LAST_STATUS" == "hardware_down" ]; then
            curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
            -d chat_id="$CHAT_ID" \
            -d text="$SERVICE_RECOVERED_MESSAGE"
            rm -f $LAST_NOTIFICATION_FILE
        fi
        echo "running" > $LAST_STATUS_FILE
    fi
fi
