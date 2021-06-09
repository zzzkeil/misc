#!/bin/bash

read -p "teamspeak version nummer (e.g. 3.13.5) : " -e -i 3.13.5 tsversion
read -p "teamspeak arch (amd64 or ) : " -e -i amd64 tsarch
read -p "teamspeak-service username : " -e -i tsuserservice tsserver
read -p "default_voice_port : " -e -i 9987 dvp
read -p "filetransfer_port : " -e -i 30033 ftp
read -p "query_port : " -e -i 10011 qp
read -p "query_ssh_port : " -e -i 10022 qpssh
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

echo "
machine_id=
default_voice_port=$dvp
voice_ip=0.0.0.0, ::
licensepath=
filetransfer_port=$ftp
filetransfer_ip=0.0.0.0, ::
query_port=$qp
query_ip=0.0.0.0, ::
query_ip_whitelist=query_ip_whitelist.txt
query_ssh_ip=0.0.0.0,::
query_ssh_port=$qpssh
dbplugin=ts3db_sqlite3
dbpluginparameter=
dbsqlpath=sql/
dbsqlcreatepath=create_sqlite/
dblogkeepdays=120
logpath=logs/
logquerycommands=0
dbclientkeepdays=360
" >> /opt/teamspeak/teamspeak3-server_linux_$tsarch/ts3server.ini
chown -R tsuserservice /opt/teamspeak/teamspeak3-server_linux_$tsarch/ts3server.ini


ufw allow $dvp/udp
ufw allow $ftp/tcp
ufw allow $qp/tcp
ufw allow $qpssh/tcp
ufw reload

systemctl enable teamspeak-server

exit
