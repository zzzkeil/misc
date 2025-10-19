#!/bin/bash
sudo apt update ; sudo apt upgrade -y
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

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y


sudo mkdir -p /opt/goaway-proxy/certs
sudo mkdir -p /opt/goaway/config
sudo mkdir -p /opt/goaway/data
sudo chown -R $USER:$USER /opt/goaway-proxy
sudo chown -R $USER:$USER /opt/goaway
sudo usermod -aG docker $USER

hostipv4=$(hostname -I | awk '{print $1}')

echo "
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_ca
prompt = no

[req_distinguished_name]
C = DE
ST = Home
L = raspberry
O = GoAway
OU = BlockAds
CN = $hostipv4

[v3_ca]
subjectAltName = @alt_names

[alt_names]
IP.1 = $hostipv4
" > /opt/goaway-proxy/cert.conf

openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -keyout /opt/goaway-proxy/certs/goaway.key \
  -out /opt/goaway-proxy/certs/goaway.crt \
  -config /opt/goaway-proxy/cert.conf

echo "
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name $hostipv4;

    ssl_certificate /etc/nginx/certs/goaway.crt;
    ssl_certificate_key /etc/nginx/certs/goaway.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384';

    location / {
        # Forward requests to the goaway container
        # 'goaway' is the service name from the docker-compose file
        # 8080 is the internal WEBSITE_PORT for the goaway app
        proxy_pass http://goaway:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Optional: Redirect HTTP (port 80) to HTTPS (port 443)
server {
    listen 80;
    listen [::]:80;
    server_name $hostipv4;

    return 301 https://$host$request_uri;
}

" > /opt/goaway-proxy/nginx.conf


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
      - WEBSITE_PORT=8080 
    ports:
      - "${DNS_PORT:-53}:${DNS_PORT:-53}/udp"
      - "${DNS_PORT:-53}:${DNS_PORT:-53}/tcp"
    cap_add:
      - NET_BIND_SERVICE
      - NET_RAW
    networks:
      - default

  nginx-proxy:
    image: nginx:latest
    container_name: goaway-proxy
    restart: unless-stopped
    ports:
      - "443:443"
      - "80:80"
    volumes:
      - /opt/goaway-proxy/nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - /opt/goaway-proxy/certs:/etc/nginx/certs:ro
    networks:
      - default

networks:
  default:
' > /opt/goaway/compose.yaml

cd /opt/goaway

echo "docker compose up > password notes /  docker compose down  / docker compose up -d"
exec su -l $USER
