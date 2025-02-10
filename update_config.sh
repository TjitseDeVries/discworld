#!/bin/bash

CONFIG_FILE="/boot/firmware/config.txt"
BACKUP_FILE="/boot/firmware/config.txt.bak"

echo "Checking configuration changes for $CONFIG_FILE..."

# Step 1: Create a backup before making changes
if [ ! -f "$BACKUP_FILE" ]; then
    echo "Creating backup at $BACKUP_FILE..."
    sudo cp "$CONFIG_FILE" "$BACKUP_FILE"
else
    echo "Backup already exists."
fi

# Step 2: Prepare the proposed changes

# 2a. Check if 'camera_auto_detect=1' needs to be commented out
if grep -q "^camera_auto_detect=1" "$CONFIG_FILE"; then
    CHANGE1="Comment out 'camera_auto_detect=1'"
else
    CHANGE1="No change to 'camera_auto_detect=1'"
fi

# 2b. Check if 'start_x=1' needs to be added
if ! grep -q "^start_x=1" "$CONFIG_FILE"; then
    CHANGE2="Add 'start_x=1'"
else
    CHANGE2="No change to 'start_x=1'"
fi

# 2c. Check if 'gpu_mem=128' needs to be added
if ! grep -q "^gpu_mem=128" "$CONFIG_FILE"; then
    CHANGE3="Add 'gpu_mem=128'"
else
    CHANGE3="No change to 'gpu_mem=128'"
fi

# Step 3: Display proposed changes
echo -e "\nProposed Changes:"
echo "1. $CHANGE1"
echo "2. $CHANGE2"
echo "3. $CHANGE3"

# Step 4: Ask for confirmation before proceeding
read -p "Apply these changes? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "No changes made."
    exit 0
fi

# Step 5: Apply changes

# 5a. Comment out 'camera_auto_detect=1' if necessary
if grep -q "^camera_auto_detect=1" "$CONFIG_FILE"; then
    echo "Commenting out 'camera_auto_detect=1'..."
    sudo sed -i '/^camera_auto_detect=1/s/^/# Disabled by update_config.sh: /' "$CONFIG_FILE"
fi

# 5b. Add 'start_x=1' if missing
if ! grep -q "^start_x=1" "$CONFIG_FILE"; then
    echo "Adding 'start_x=1'..."
    echo -e "\n# Added by update_config.sh\nstart_x=1" | sudo tee -a "$CONFIG_FILE" > /dev/null
fi

# 5c. Add 'gpu_mem=128' if missing
if ! grep -q "^gpu_mem=128" "$CONFIG_FILE"; then
    echo "Adding 'gpu_mem=128'..."
    echo -e "\n# Added by update_config.sh\ngpu_mem=128" | sudo tee -a "$CONFIG_FILE" > /dev/null
fi

# Step 6: Display final changes
echo -e "\nFinal Configuration Updates:"
grep -E "^(start_x=1|gpu_mem=128|# Disabled by update_config.sh: camera_auto_detect=1)" "$CONFIG_FILE"

# Step 7: Prompt for reboot
read -p "Changes applied. A reboot is required. Reboot now? (y/N): " REBOOT
if [[ "$REBOOT" =~ ^[Yy]$ ]]; then
    echo "Rebooting..."
    sudo reboot
else
    echo "Changes will take effect after a manual reboot."
fi