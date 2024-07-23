#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Variables
CODE_SERVER_VERSION="4.91.1"
DEB_PACKAGE="code-server_${CODE_SERVER_VERSION}_amd64.deb"
SERVICE_FILE="/etc/systemd/system/code-server.service"
USER="ubuntu"  # Change this to your username if different
PASSWORD="secret"  # Change this to a secure password

# Update package list
echo "Updating package list..."
sudo apt update

# Download code-server
echo "Downloading code-server version $CODE_SERVER_VERSION..."
wget https://github.com/coder/code-server/releases/download/v${CODE_SERVER_VERSION}/$DEB_PACKAGE

# Install code-server
echo "Installing code-server..."
sudo apt install ./$DEB_PACKAGE -y

# Generate self-signed certificates
echo "Generating self-signed certificates..."
mkdir -p ~/.local/share/code-server
cd ~/.local/share/code-server/
openssl req -x509 -sha256 -nodes -newkey rsa:2048 -days 365 -keyout localhost.key -out localhost.crt -subj "/CN=localhost.local"

# Create systemd service file
echo "Creating systemd service file..."
cat <<EOL | sudo tee $SERVICE_FILE
[Unit]
Description=code-server
After=nginx.service

[Service]
Type=simple
User=$USER
Group=$USER
Environment=PASSWORD=$PASSWORD
ExecStart=/usr/bin/code-server --bind-addr 0.0.0.0:5777 --auth password --cert /home/$USER/.local/share/code-server/localhost.crt --cert-host localhost.local --cert-key /home/$USER/.local/share/code-server/localhost.key 
Restart=always

[Install]
WantedBy=multi-user.target
EOL

# Enable and start code-server
echo "Enabling and starting code-server service..."
sudo systemctl enable code-server
sudo systemctl start code-server

echo "Code-server installation and setup complete!"
echo "You can access code-server at https://$HOSTNAME:5777 or https://0.0.0.0:5777"
echo "Use the password: $PASSWORD to log in."
