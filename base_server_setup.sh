#!/bin/bash
clear
echo " ###########################################"
echo " # Setup server config Netcup Ubuntu 18.04 #"
echo " # passwd,ssh,fail2ban,ufw,network,updates #"
echo " # !!!!!!!!!! Automatic reboot !!!!!!!!!!! #"
echo " ###########################################"
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

#
# APT
#
echo "apt update and install"
apt update && apt upgrade -y && apt autoremove -y
apt install ufw fail2ban -y 
mkdir /root/script_backupfiles/
clear
#
# Password
#
echo "Set root password"
echo "This script creates a random password - use it, or not"
randompasswd=$(</dev/urandom tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~' | head -c 44  ; echo)
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
nano /etc/netplan/50-cloud-init.yaml
clear
#
# UFW
#
echo "Set ufw config"
ufw default deny incoming
ufw allow $sshport/tcp
clear
#
# fail2ban
#
echo "Set fail2ban for ssh"
echo "
[sshd]
enabled = true
port = $sshport
filter = sshd
logpath = /var/log/auth.log
backend = %(sshd_backend)s
maxretry = 3
banaction = ufw
findtime = 3600
bantime = 172800
" >> /etc/fail2ban/jail.d/ssh.conf
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
nano /etc/apt/apt.conf.d/50unattended-upgrades
clear
#
#misc
#
echo "Clear some stuff"
chmod -x /etc/update-motd.d/10-help-text
chmod -x /etc/update-motd.d/50-motd-news
chmod -x /etc/update-motd.d/80-livepatch
clear
#
# END
#
systemctl enable fail2ban.service
read -p "Press enter to reboot"
ufw --force enable
ufw reload
reboot
