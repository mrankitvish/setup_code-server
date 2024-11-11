#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Detect the current user
USER=$(whoami)
SERVICE_FILE="/etc/systemd/system/code-server.service"
PASSWORD=${PASSWORD:-"$(openssl rand -base64 16)"}

# Determine the package manager
if command -v apt > /dev/null; then
    PACKAGE_MANAGER="apt"
elif command -v dnf > /dev/null; then
    PACKAGE_MANAGER="dnf"
elif command -v yum > /dev/null; then
    PACKAGE_MANAGER="yum"
elif command -v zypper > /dev/null; then
    PACKAGE_MANAGER="zypper"
else
    echo "Unsupported package manager. Install code-server manually."
    exit 1
fi

# Update packages and install prerequisites
echo "Updating packages and installing prerequisites..."
case $PACKAGE_MANAGER in
    apt)
        sudo apt update && sudo apt install -y wget openssl;;
    dnf|yum)
        sudo $PACKAGE_MANAGER install -y wget openssl;;
    zypper)
        sudo zypper refresh && sudo zypper install -y wget openssl;;
esac

# Define the latest version and package URLs
CODE_SERVER_VERSION="4.95.1"
DEB_PACKAGE="code-server_${CODE_SERVER_VERSION}_amd64.deb"
RPM_PACKAGE="code-server-${CODE_SERVER_VERSION}-amd64.rpm"

# Download and install code-server based on package manager
echo "Downloading code-server version $CODE_SERVER_VERSION..."
if [[ "$PACKAGE_MANAGER" == "apt" ]]; then
    wget https://github.com/coder/code-server/releases/download/v${CODE_SERVER_VERSION}/$DEB_PACKAGE
    echo "Installing code-server..."
    sudo apt install ./$DEB_PACKAGE -y
    rm $DEB_PACKAGE
elif [[ "$PACKAGE_MANAGER" == "dnf" || "$PACKAGE_MANAGER" == "yum" || "$PACKAGE_MANAGER" == "zypper" ]]; then
    wget https://github.com/coder/code-server/releases/download/v${CODE_SERVER_VERSION}/$RPM_PACKAGE
    echo "Installing code-server..."
    sudo $PACKAGE_MANAGER install ./$RPM_PACKAGE -y
    rm $RPM_PACKAGE
else
    echo "Package installation for code-server is only supported on apt, dnf, yum, and zypper."
    exit 1
fi

# Generate self-signed certificates
echo "Generating self-signed certificates..."
CERT_PATH="/home/$USER/.local/share/code-server"
mkdir -p $CERT_PATH
cd $CERT_PATH
openssl req -x509 -sha256 -nodes -newkey rsa:2048 -days 365 -keyout localhost.key -out localhost.crt -subj "/CN=localhost.local"

# Create systemd service file
echo "Creating systemd service file..."
cat <<EOL | sudo tee $SERVICE_FILE
[Unit]
Description=code-server
After=network.target

[Service]
Type=simple
User=$USER
Environment=PASSWORD=$PASSWORD
ExecStart=/usr/bin/code-server --bind-addr 0.0.0.0:5777 --auth password --cert $CERT_PATH/localhost.crt --cert-key $CERT_PATH/localhost.key
Restart=always

[Install]
WantedBy=multi-user.target
EOL

# Enable and start code-server
echo "Enabling and starting code-server service..."
sudo systemctl daemon-reload
sudo systemctl enable code-server
sudo systemctl start code-server

echo "Code-server installation and setup complete!"
echo "You can access code-server at https://$HOSTNAME:5777 or https://0.0.0.0:5777"
echo "Use the password: $PASSWORD to log in."
