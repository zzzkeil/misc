#!/bin/bash
clear
echo " #############################################"
echo " # Not ready to run !!!!!!!!!!!!!!!!!!!!!!!  #"
echo " #############################################"
echo ""
echo ""
echo "To EXIT this script press  [ENTER]"
echo 
read -p "To RUN this script press  [Y]" -n 1 -r
echo
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

if [[ "$EUID" -ne 0 ]]; then
	echo "Sorry, you need to run this as root"
	exit 1
fi

if [[ -e /etc/debian_version ]]; then
      echo "Debian Distribution"
      else
      echo "This is not a Debian Distribution."
      exit 1
fi

#
# APT
#
echo "apt update and install"
apt update && apt upgrade -y && apt autoremove -y
apt install ufw fail2ban  unattended-upgrades apt-listchanges -y 
mkdir /root/script_backupfiles/
clear
#
# mailcow docker setup
#
curl -sSL https://get.docker.com/ | CHANNEL=stable sh
systemctl enable docker.service
systemctl start docker.service
curl -L https://github.com/docker/compose/releases/download/$(curl -Ls https://www.servercow.de/docker-compose/latest.php)/docker-compose-$(uname -s)-$(uname -m) > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
#
# Password
#
echo "Set root password"
echo "This script creates a random password - use it, or not"
randompasswd=$(</dev/urandom tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~' | head -c 56  ; echo)
echo "Random Password  - mark it once, right mouse klick, enter, and again !"
echo "$randompasswd"
passwd
read -p "Press enter to continue / on fail press CRTL+C"
clear
#
# SSH
#
echo "Set ssh config"
read -p "Choose your SSH Port: (default 22) " -e -i 2222 sshport
ssh-keygen -f /etc/ssh/key1rsa -t rsa -b 4096 -N ""
ssh-keygen -f /etc/ssh/key2ecdsa -t ecdsa -b 521 -N ""
ssh-keygen -f /etc/ssh/key3ed25519 -t ed25519 -N ""

mv /etc/ssh/sshd_config /root/script_backupfiles/sshd_config.orig
echo "Port $sshport
HostKey /etc/ssh/key1rsa
HostKey /etc/ssh/key2ecdsa
HostKey /etc/ssh/key3ed25519
PermitRootLogin yes
PasswordAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
PermitEmptyPasswords no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem	sftp	/usr/lib/openssh/sftp-server" >> /etc/ssh/sshd_config
clear
#
# Network
#
echo "Set network config"
read -p "Your hostname :" -e -i remotehost hostnamex
hostnamectl set-hostname $hostnamex
if [ -f "/etc/netplan/50-cloud-init.yaml" ]; then
    nano /etc/netplan/50-cloud-init.yaml
fi
if [ -f "/etc/network/interfaces.d/50-cloud-init.cfg" ]; then
   nano /etc/network/interfaces.d/50-cloud-init.cfg
fi

clear
#
# UFW
#
echo "Set ufw config for with docker"
sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
echo"
*nat
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING ! -o docker0 -s 172.22.1.0/24 -j MASQUERADE
COMMIT
" >> /etc/ufw/after.rules
echo"
*nat
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING ! -o docker0 -s fd4d:6169:6c63:6f77::/64 -j MASQUERADE
COMMIT
" >> /etc/ufw/after6.rules
ufw default deny incoming
ufw allow $sshport/tcp
ufw allow 25/tcp
ufw allow 80/tcp
ufw allow 110/tcp
ufw allow 143/tcp
ufw allow 443/tcp
ufw allow 465/tcp
ufw allow 587/tcp
ufw allow 993/tcp
ufw allow 995/tcp
ufw allow 4190/tcp
echo"
{
    "iptables": false
}
" > /etc/docker/daemon.json
clear
systemctl restart docker.service
#
# fail2ban
#
echo "Set fail2ban for ssh"
echo "[sshd]
enabled = true
port = $sshport
filter = sshd
logpath = /var/log/auth.log
backend = %(sshd_backend)s
maxretry = 3
banaction = ufw
findtime = 1d
bantime = 18w
" > /etc/fail2ban/jail.d/ssh.conf
sed -i "/blocktype = reject/c\blocktype = deny" /etc/fail2ban/action.d/ufw.conf
clear
#
# Updates
#
echo "unattended-upgrades"
mv /etc/apt/apt.conf.d/50unattended-upgrades /root/script_backupfiles/50unattended-upgrades.orig
echo 'Unattended-Upgrade::Allowed-Origins {
        "${distro_id}:${distro_codename}";
	"${distro_id}:${distro_codename}-security";
	"${distro_id}ESM:${distro_codename}";
//	"${distro_id}:${distro_codename}-updates";
//	"${distro_id}:${distro_codename}-proposed";
//	"${distro_id}:${distro_codename}-backports";
};
Unattended-Upgrade::Package-Blacklist {
};
Unattended-Upgrade::DevRelease "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "02:22";
' >> /etc/apt/apt.conf.d/50unattended-upgrades

echo '
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
' >> /etc/apt/apt.conf.d/20auto-upgrades


nano /etc/apt/apt.conf.d/50unattended-upgrades
nano /etc/apt/apt.conf.d/20auto-upgrades

sed -i "s@6,18:00@9,23:00@" /lib/systemd/system/apt-daily.timer
sed -i "s@12h@1h@" /lib/systemd/system/apt-daily.timer
sed -i "s@6:00@1:00@" /lib/systemd/system/apt-daily-upgrade.timer
clear
#
#misc
#
echo "Clear/Change some stuff"
chmod -x /etc/update-motd.d/10-help-text
chmod -x /etc/update-motd.d/50-motd-news
chmod -x /etc/update-motd.d/80-livepatch

echo '#!/bin/sh
runtime1=$(uptime -s)
runtime2=$(uptime -p)
totalban1=$(zgrep 'Ban' /var/log/fail2ban.log* | wc -l)
echo "System uptime : $runtime1  / $runtime2 "
echo ""
echo "Total banned IPs from fail2ban : $totalban1 "
' >> /etc/update-motd.d/99-base01
chmod +x /etc/update-motd.d/99-base01
clear
#
# END
#
systemctl enable fail2ban.service
cd /opt
git clone https://github.com/mailcow/mailcow-dockerized
read -p "Press enter to reboot"
ufw --force enable
ufw reload
reboot
