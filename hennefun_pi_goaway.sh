#!/bin/bash

for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo mkdir /opt/goaway
sudo mkdir /opt/goaway/config
sudo mkdir /opt/goaway/data
sudo chown -R $USER:$USER /opt/goaway
sudo usermod -aG docker $USER
exec su -l $USER


echo '
services:
  goaway:
    image: pommee/goaway:latest
    container_name: goaway
    restart: unless-stopped
    volumes:
      - /opt/goaway/config:/app/config  # Custom settings.yaml configuration
      - /opt/goaway/data:/app/data      # Database storage location
    environment:
      - DNS_PORT=${DNS_PORT:-53}
      - WEBSITE_PORT=${WEBSITE_PORT:-8443}
    #  - DOT_PORT=${DOT_PORT:-853}  # Port for DoT
    ports:
      - "${DNS_PORT:-53}:${DNS_PORT:-53}/udp"
      - "${DNS_PORT:-53}:${DNS_PORT:-53}/tcp"
      - "${WEBSITE_PORT:-8443}:${WEBSITE_PORT:-8443}/tcp"
    #  - "${DOT_PORT:-853}:${DOT_PORT:-853}/tcp"
    cap_add:
      - NET_BIND_SERVICE
      - NET_RAW
' > /opt/goaway/compose.yaml

cd /opt/goaway

echo "docker compose up > password notes /  docker compose down  / docker compose up -d"
