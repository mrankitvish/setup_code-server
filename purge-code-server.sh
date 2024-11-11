#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Prompt for user confirmation
read -p "Are you sure you want to remove code-server and all associated files? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
    echo "Aborting cleanup."
    exit 0
fi

# Detect the package manager
if command -v apt > /dev/null; then
    PACKAGE_MANAGER="apt"
elif command -v dnf > /dev/null; then
    PACKAGE_MANAGER="dnf"
elif command -v yum > /dev/null; then
    PACKAGE_MANAGER="yum"
elif command -v zypper > /dev/null; then
    PACKAGE_MANAGER="zypper"
else
    echo "Unsupported package manager. Manual cleanup may be required."
    exit 1
fi

# Stop and disable code-server service
echo "Stopping and disabling code-server service..."
sudo systemctl stop code-server
sudo systemctl disable code-server

# Remove code-server installation
echo "Removing code-server package..."
case $PACKAGE_MANAGER in
    apt)
        sudo apt remove --purge -y code-server;;
    dnf|yum)
        sudo $PACKAGE_MANAGER remove -y code-server;;
    zypper)
        sudo zypper rm -y code-server;;
esac

# Remove the systemd service file if it exists
SERVICE_FILE="/etc/systemd/system/code-server.service"
if [[ -f $SERVICE_FILE ]]; then
    echo "Removing code-server systemd service file..."
    sudo rm -f $SERVICE_FILE
    sudo systemctl daemon-reload
fi

# Remove user configuration and certificates
echo "Removing code-server configuration and certificates..."
CERT_PATH="/home/$(whoami)/.local/share/code-server"
if [[ -d $CERT_PATH ]]; then
    rm -rf $CERT_PATH
fi

echo "Cleanup completed! Code-server and associated files have been removed."
