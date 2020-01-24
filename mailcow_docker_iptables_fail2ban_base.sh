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
apt install fail2ban -y 
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
clear
systemctl restart docker.service
#
# fail2ban 4 host
#
echo "Set fail2ban for ssh"
echo "
[sshd]
enabled = true
chain = DOCKER-USER
port = $sshport
filter = sshd
logpath = /var/log/auth.log
backend = %(sshd_backend)s
maxretry = 3
banaction = iptables-allports
findtime = 1d
bantime = 18w
" >> /etc/fail2ban/jail.d/ssh.conf
mv /etc/fail2ban/jail.d/defaults-debian.conf /etc/fail2ban/jail.d/defaults-debian.conf.bak
systemctl enable fail2ban.service
clear
cd /opt
git clone https://github.com/mailcow/mailcow-dockerized
cd mailcow-dockerized
echo " Now continue with STEP 3 from https://mailcow.github.io/mailcow-dockerized-docs/i_u_m_install/"
echo " Do not forget to reboot your system after all "



