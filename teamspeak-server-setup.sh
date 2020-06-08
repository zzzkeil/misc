#!/bin/bash

read -p "teamspeak version nummer (e.g. 3.8.0) : " -e -i 3.12.1 tsversion
read -p "teamspeak arch (amd64 or ) : " -e -i amd64 tsarch
read -p "teamspeak-service username : " -e -i tsuserservice tsserver
mkdir /opt/teamspeak
ln -s /opt/teamspeak/ /root/teamspeak_folder
cd /opt/teamspeak
wget -O teamspeak3-server.tar.bz2 https://files.teamspeak-services.com/releases/server/$tsversion/teamspeak3-server_linux_$tsarch-$tsversion.tar.bz2
chmod +x teamspeak3-server.tar.bz2
tar xjf teamspeak3-server.tar.bz2
touch /opt/teamspeak/teamspeak3-server_linux_amd64/.ts3server_license_accepted
useradd -M -N -r -s /bin/false -c "user to run teamspeak-services" $tsserver
chmod +x /opt/teamspeak/teamspeak3-server_linux_amd64/ts3server
chown -R $tsserver /opt/teamspeak

echo "
[Unit]
Description=Team Speak 3 Server
After=network.target
[Service]
WorkingDirectory=/opt/teamspeak/teamspeak3-server_linux_amd64/
User=$tsserver
Type=forking
ExecStart=/opt/teamspeak/teamspeak3-server_linux_amd64/ts3server_startscript.sh start
ExecStop=/opt/teamspeak/teamspeak3-server_linux_amd64/ts3server_startscript.sh stop
PIDFile=/opt/teamspeak/teamspeak3-server_linux_amd64/ts3server.pid
RestartSec=15
Restart=always

[Install]
WantedBy=multi-user.target
" >> /etc/systemd/system/teamspeak-server.service


systemctl enable teamspeak-server

exit
