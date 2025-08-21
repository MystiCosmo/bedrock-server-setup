#!/bin/bash
set -e

# Variables
SERVER_DIR="/opt/bedrock"
USER="minecraft"
SESSION="bedrock"

# Ensure system is updated
apt-get update && apt-get upgrade -y
apt-get install -y unzip curl screen cron

# Create minecraft user if not exists
if ! id -u $USER > /dev/null 2>&1; then
    useradd -m -r -d $SERVER_DIR -s /bin/bash $USER
fi

mkdir -p $SERVER_DIR
chown -R $USER:$USER $SERVER_DIR
cd $SERVER_DIR

# Download Bedrock server
LATEST_URL=$(curl -s https://www.minecraft.net/en-us/download/server/bedrock | grep -o 'https://minecraft\.azureedge\.net/bin-linux/bedrock-server-.*zip')
curl -o bedrock-server.zip "$LATEST_URL"
sudo -u $USER unzip -o bedrock-server.zip
rm bedrock-server.zip

# Create CLI wrapper
cat << 'EOF' > $SERVER_DIR/bedrock-cli.sh
#!/bin/bash
SERVER_DIR="/opt/bedrock"
SESSION="bedrock"

case "$1" in
  start)
    if screen -list | grep -q "$SESSION"; then
      echo "Server already running."
    else
      cd $SERVER_DIR
      screen -dmS $SESSION ./bedrock_server
      echo "Server started."
    fi
    ;;
  stop)
    screen -S $SESSION -p 0 -X stuff "stop$(printf '\r')"
    echo "Server stopped."
    ;;
  restart)
    $0 stop
    sleep 5
    $0 start
    ;;
  attach)
    screen -r $SESSION
    ;;
  save)
    screen -S $SESSION -p 0 -X stuff "save hold$(printf '\r')"
    sleep 2
    screen -S $SESSION -p 0 -X stuff "save query$(printf '\r')"
    sleep 2
    screen -S $SESSION -p 0 -X stuff "save resume$(printf '\r')"
    echo "World saved."
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|attach|save}"
    ;;
esac
EOF
chmod +x $SERVER_DIR/bedrock-cli.sh
chown $USER:$USER $SERVER_DIR/bedrock-cli.sh

# Create updater script
cat << 'EOF' > $SERVER_DIR/bedrock_update.sh
#!/bin/bash
set -e
SERVER_DIR="/opt/bedrock"
USER="minecraft"
SESSION="bedrock"

echo "=== Stopping server ==="
$SERVER_DIR/bedrock-cli.sh stop || true
sleep 5

echo "=== Downloading latest Bedrock release ==="
cd $SERVER_DIR
LATEST_URL=$(curl -s https://www.minecraft.net/en-us/download/server/bedrock | grep -o 'https://minecraft\.azureedge\.net/bin-linux/bedrock-server-.*zip')
curl -o bedrock-server.zip "$LATEST_URL"

echo "=== Backing up old binaries ==="
mkdir -p $SERVER_DIR/old
timestamp=$(date +%Y%m%d-%H%M%S)
tar -czf "old/bedrock-binaries-$timestamp.tar.gz" bedrock_server* mcpe* resource_packs/ definitions/ 2>/dev/null || true

echo "=== Extracting update ==="
sudo -u $USER unzip -o bedrock-server.zip
rm bedrock-server.zip

echo "=== Restarting server ==="
$SERVER_DIR/bedrock-cli.sh start

echo "=== Update complete! ==="
EOF
chmod +x $SERVER_DIR/bedrock_update.sh
chown $USER:$USER $SERVER_DIR/bedrock_update.sh

# Create systemd service with auto-update at startup
cat << EOF > /etc/systemd/system/bedrock.service
[Unit]
Description=Minecraft Bedrock Server
After=network.target

[Service]
User=$USER
WorkingDirectory=$SERVER_DIR
ExecStart=$SERVER_DIR/bedrock_update.sh
ExecStop=$SERVER_DIR/bedrock-cli.sh stop
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Enable service
systemctl daemon-reload
systemctl enable bedrock.service
systemctl start bedrock.service

# Setup cron jobs for autosave and nightly restart
(crontab -u $USER -l 2>/dev/null; echo "*/5 * * * * $SERVER_DIR/bedrock-cli.sh save") | crontab -u $USER -
(crontab -u $USER -l 2>/dev/null; echo "0 0 * * * $SERVER_DIR/bedrock-cli.sh restart") | crontab -u $USER -

echo "Installation complete! Use $SERVER_DIR/bedrock-cli.sh {start|stop|restart|attach|save}"
