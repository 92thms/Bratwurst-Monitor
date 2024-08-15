# Bratwurst-ADSB Monitoring Script

This project monitors the health of your SDR stick (e.g., RTL2838) and readsb.service. It sends notifications to a Telegram chat in case of issues or recoveries.

Informs if readsb is down longer >5min and/or USB Connection to the SDR Stick got disconnect. 
Also sends a reminder notification every 24h if the service or device stays down. 

## Prerequisites

- A RaspberryPi (or other) with an SDR stick (e.g., RTL2838) running Bratwurst-ADSB or similar.
- A Telegram account and bot.
- systemd.

## Setup Instructions

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/92thms/Bratwurst-Monitor.git
   cd Bratwurst-Monitor
   ```

2. **Run the Setup Script:**

   The setup script will guide you through selecting your SDR stick and configuring Telegram notifications.

   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

   The setup process will:
   - Prompt you to select your USB device (SDR stick).
   - Ask for your Telegram Bot Token and Chat ID.
   - Setup the config.yaml
   - Set up the systemd service and timer to start monitoring.

## Uninstallation

To remove the script, use the `uninstall.sh` script:

```bash
chmod +x uninstall.sh
./uninstall.sh
```

This will stop and disable the monitoring services and remove the related files from your system.
