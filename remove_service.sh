#!/bin/bash

SERVICE_NAME="v4l2rtspserver.service"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"
SERVICE_USER="v4l2rtsp"

echo "Removing $SERVICE_NAME..."

# Step 1: Stop the service if it's running
if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "Stopping $SERVICE_NAME..."
    sudo systemctl stop "$SERVICE_NAME"
else
    echo "$SERVICE_NAME is not running."
fi

# Step 2: Disable the service (prevents auto-start on boot)
if systemctl is-enabled --quiet "$SERVICE_NAME"; then
    echo "Disabling $SERVICE_NAME..."
    sudo systemctl disable "$SERVICE_NAME"
else
    echo "$SERVICE_NAME is already disabled."
fi

# Step 3: Remove the service file
if [ -f "$SERVICE_PATH" ]; then
    echo "Deleting service file..."
    sudo rm "$SERVICE_PATH"
else
    echo "Service file not found, skipping."
fi

# Step 4: Reload systemd daemon
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

# Step 5: Check if the user is running any processes before removing
if id "$SERVICE_USER" &>/dev/null; then
    if pgrep -u "$SERVICE_USER" &>/dev/null; then
        echo "User $SERVICE_USER is running processes. Not removing."
    else
        echo "Removing user $SERVICE_USER..."
        sudo userdel -r "$SERVICE_USER"
    fi
else
    echo "User $SERVICE_USER does not exist."
fi

# Step 6: Verify service is removed
if systemctl list-unit-files | grep -q "^$SERVICE_NAME"; then
    echo "Warning: $SERVICE_NAME still appears in systemd list."
else
    echo "$SERVICE_NAME successfully removed."
fi