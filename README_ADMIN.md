# Minecraft Bedrock Server (Ubuntu Server Setup)

## Overview
This repository provides scripts to fully automate the installation and management of a Minecraft Bedrock Dedicated Server on Ubuntu Server.  
It is intended for **server administrators** who want reliable startup, automated updates, autosaves, and scheduled restarts.

The setup includes:
- Automatic Bedrock server installation
- Automatic update check & apply at every server startup
- Systemd integration (server runs as a service and restarts on crashes)
- Cron jobs for autosaves (every 5 minutes) and daily restart (midnight)
- CLI management tool (`bedrock-cli.sh`)

---

## Files
- **bedrock_install.sh** → Automates the full installation & configuration of the server  
- **bedrock_update.sh** → Script used internally & manually to update server binaries  
- **README_ADMIN.md** → This document (technical details)  
- **README_PLAYERS.md** → Simplified instructions for connecting players  

---

## Installation Instructions (Fresh Ubuntu)
Run these commands one by one on your Ubuntu server:

```bash
sudo apt-get install -y curl git
git clone https://github.com/<YOUR_GITHUB_USERNAME>/<YOUR_REPO>.git
cd <YOUR_REPO>
chmod +x bedrock_install.sh
sudo ./bedrock_install.sh
