#!/bin/bash

# Colors for visual appeal
GREEN="\033[0;32m"
CYAN="\033[0;36m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
NC="\033[0m" # No Color

# Function to display the header
display_header() {
    echo -e "${RED}"
    echo "###############################################"
    echo "#                                             #"
    echo "#       Bratwurst-ADSB Monitoring Script      #"
    echo "#               Uninstall Script              #"
    echo "#                                             #"
    echo "###############################################"
    echo -e "${NC}"
}

# Function to stop and disable the systemd service and timer
disable_and_remove_service() {
    echo -e "${YELLOW}Stopping and disabling systemd service and timer...${NC}"
    sudo systemctl stop bratwurst_monitor.timer
    sudo systemctl disable bratwurst_monitor.timer

    echo -e "${YELLOW}Removing systemd service and timer files...${NC}"
    sudo rm /etc/systemd/system/bratwurst_monitor.service
    sudo rm /etc/systemd/system/bratwurst_monitor.timer

    echo -e "${GREEN}Systemd service and timer have been removed.${NC}"
}

# Function to clean up script files
clean_up_files() {
    SCRIPT_DIR=$(pwd)
    echo -e "${YELLOW}Removing system monitor script from: $SCRIPT_DIR${NC}"
    rm -f "$SCRIPT_DIR/bratwurst_monitor.sh"

    echo -e "${GREEN}Cleanup complete. The monitoring script has been removed.${NC}"
}

# Main script execution
display_header
disable_and_remove_service
clean_up_files

echo -e "${CYAN}Uninstallation complete!${NC} ${GREEN}The Bratwurst-ADSB Monitoring Script has been fully removed.${NC}"
