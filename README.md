## Code-Server Installation with Self-Signed Certificates
This guide provides step-by-step instructions to install code-server and configure it to use self-signed certificates.
### Prerequisites

- A system running Ubuntu.
- Basic knowledge of using the terminal.

### Installation Steps

Step 1. Download Code-Server Use wget to download the latest version of code-server:

```bash
wget https://github.com/coder/code-server/releases/download/v4.91.1/code-server_4.91.1_amd64.deb
```
Step 2. Install Code-Server Install the downloaded .deb package:

```bash
sudo apt install ./code-server_4.91.1_amd64.deb -y
```
Step 3. Generate Self-Signed Certificates Navigate to the code-server directory and generate a self-signed certificate:

```bash
cd ~/.local/share/code-server/
openssl req -x509 -sha256 -nodes -newkey rsa:2048 -days 365 -keyout localhost.key -out localhost.crt
```
`Follow the prompts to fill in the required information.`

Step 4. Create Systemd Service File Open the systemd service file for code-server:

```bash
sudo vi /etc/systemd/system/code-server.service
```
Add the following configuration:

```text
[Unit]
Description=code-server
After=nginx.service

[Service]
Type=simple
User=ubuntu
Group=ubuntu
Environment=PASSWORD=secret
ExecStart=/usr/bin/code-server --bind-addr 0.0.0.0:5777 --auth password --cert /home/ubuntu/.local/share/code-server/localhost.crt --cert-host localhost.local --cert-key /home/ubuntu/.local/share/code-server/localhost.key 
Restart=always

[Install]
WantedBy=multi-user.target
```
Step 5. Enable and Start Code-Server Enable the code-server service to start on boot and then start the service:

```bash
sudo systemctl enable code-server
sudo systemctl start code-server
```
Accessing Code-Server
You can now access code-server by navigating to `https://localhost.local:5777`in your web browser. 
Use the password specified in the service file to log in.

`Note`
Make sure to replace ubuntu in the service file with your actual username if it differs. Adjust the `PASSWORD` environment variable as needed for security purposes.
