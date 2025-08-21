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
