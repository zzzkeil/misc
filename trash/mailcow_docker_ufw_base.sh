#!/bin/bash
clear
echo " #############################################"
echo " # Not tested / Not ready to run maybe       #"
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
apt install ufw fail2ban -y 
mkdir /root/script_backupfiles/
clear
echo " Make sure you use the right SSH port now ! "
read -p "Choose your SSH Port: (default 22) " -e -i 22 sshport
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
# UFW
#
# https://blog.marvin-menzerath.de/artikel/docker-ufw-iptables-ports-nicht-automatisch-oeffnen/
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
ufw --force enable
ufw reload
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
findtime = 1d
bantime = 18w
" >> /etc/fail2ban/jail.d/ssh.conf
sed -i "/blocktype = reject/c\blocktype = deny" /etc/fail2ban/action.d/ufw.conf
systemctl enable fail2ban.service
clear
cd /opt
git clone https://github.com/mailcow/mailcow-dockerized
cd mailcow-dockerized
echo " Now continue with STEP 3 from https://mailcow.github.io/mailcow-dockerized-docs/i_u_m_install/"
echo " Do not forget to reboot your system after all "



