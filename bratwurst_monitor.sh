#!/bin/bash

# Configuration
DEVICE_ID="PLACEHOLDER_FOR_DEVICE_ID" # Replace with your USB device ID, e.g., "0bda:2838"
SERVICE_NAME="readsb.service" # Service to monitor (constant)
BOT_TOKEN="PLACEHOLDER_FOR_TELEGRAM_BOT_TOKEN" # Replace with your Telegram Bot Token
CHAT_ID="PLACEHOLDER_FOR_TELEGRAM_CHAT_ID" # Replace with your Telegram Chat ID
LAST_NOTIFICATION_FILE="/tmp/last_notification_time" # File to track the last notification time
LAST_STATUS_FILE="/tmp/last_service_status" # File to track the last known service status

# Messages
DEVICE_MESSAGE="SDR Device is not detected. Please check the connection."
SERVICE_MESSAGE="READSB service is not running anymore. Please check it."
SERVICE_RECOVERED_MESSAGE="READSB service is running again!"

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
