#!/bin/bash
clear
echo " ####################################################################"
echo " # Setup server config Netcup Ubuntu 18.04- passwd,ssh,fail2ban,ufw #"
echo " # Not tested for now, maybe not working                            #"
echo " ####################################################################"
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
clear
#
# APT
#
echo "apt update and install"
apt update && apt upgrade -y && apt autoremove -y
apt install ufw fail2ban -y 
clear
#
# Password
#
echo "Set root password - long 32 char one"
echo "This script creates a random password with GPG"
randompasswd=$(gpg --gen-random --armor 2 32)
echo "Random Password $randompasswd"
passwd 
read -p "Press enter to continue"
clear
#
# SSH
#
echo "Set ssh config"
read -p "Choose your SSH Port: (default 22) " -e -i 555 sshport
ssh-keygen -f /etc/ssh/key1rsa -t rsa -b 4096 -N ""
ssh-keygen -f /etc/ssh/key2ecdsa -t ecdsa -b 521 -N ""
ssh-keygen -f /etc/ssh/key3ed25519 -t ed25519 -N ""
clear
mv /etc/ssh/sshd_config /etc/ssh/sshd_config.orig
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
read -p "Press enter to continue"
clear
#
# UFW
#
echo "Set ufw config"
ufw default deny incoming
ufw default deny outgoing
ufw allow $sshport/tcp
ufw allow out 80
ufw allow out 443
ufw allow out 53
read -p "Press enter to continue"
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
bantime = 2678400
" >> /etc/fail2ban/jail.d/ssh.conf
sed -i "/blocktype = reject/c\blocktype = deny" /etc/fail2ban/action.d/ufw.conf
read -p "Press enter to continue"
clear
#
# END
#

ufw --force enable
ufw reload
systemctl restart sshd.service
systemctl enable fail2ban.service
systemctl start fail2ban.service
