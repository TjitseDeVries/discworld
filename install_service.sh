#!/bin/bash

SERVICE_NAME="v4l2rtspserver.service"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"
SERVICE_USER="v4l2rtsp"
SERVICE_GROUP="video"

echo "Deploying $SERVICE_NAME..."

# Step 1: Ensure the user exists
if ! id "$SERVICE_USER" &>/dev/null; then
    echo "Creating system user $SERVICE_USER..."
    sudo useradd -r -s /usr/sbin/nologin "$SERVICE_USER"
else
    echo "User $SERVICE_USER already exists."
fi

# Step 2: Ensure the user is in the correct group
if groups "$SERVICE_USER" | grep -q "\b$SERVICE_GROUP\b"; then
    echo "User $SERVICE_USER is already in group $SERVICE_GROUP."
else
    echo "Adding $SERVICE_USER to group $SERVICE_GROUP..."
    sudo usermod -aG "$SERVICE_GROUP" "$SERVICE_USER"
fi

# Step 3: Create the service file if it does not exist
if [ ! -f "$SERVICE_PATH" ]; then
    echo "Creating $SERVICE_NAME..."
    sudo tee "$SERVICE_PATH" > /dev/null <<EOF
[Unit]
Description=v4l2rtspserver RTSP streaming server
After=network.target

[Service]
ExecStartPre=/usr/bin/v4l2-ctl --set-ctrl h264_i_frame_period=5
ExecStartPre=/usr/bin/sleep 2
ExecStart=/usr/bin/v4l2rtspserver -F 5 -W 1920 -H 1080
Type=simple
User=$SERVICE_USER
Group=$SERVICE_GROUP
Restart=always

[Install]
WantedBy=multi-user.target
EOF
else
    echo "$SERVICE_NAME already exists. Skipping creation."
fi

# Step 4: Ensure the service user has proper permissions
echo "Adjusting permissions..."
sudo chown "$SERVICE_USER:$SERVICE_GROUP" /usr/bin/v4l2rtspserver
sudo chmod +x /usr/bin/v4l2rtspserver

# Step 5: Reload systemd daemon
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

# Step 6: Enable the service to start on boot
echo "Enabling $SERVICE_NAME..."
sudo systemctl enable "$SERVICE_NAME"

# Step 7: Start the service
echo "Starting $SERVICE_NAME..."
sudo systemctl start "$SERVICE_NAME"

# Step 8: Check service status
echo "Checking service status..."
sudo systemctl status "$SERVICE_NAME" --no-pager