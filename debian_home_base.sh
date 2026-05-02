
if [[ "$EUID" -ne 0 ]]; then
whiptail --title "Aborted" --msgbox "Sorry, you need to run this as root!" 15 80
exit 1
fi
apt-get update ; apt-get upgrade -y
apt-get install unattended-upgrades apt-listchanges -y
read -p "set sshport to: " sshport
dpkg-reconfigure tzdata

ssh-keygen -f /etc/ssh/key_ed25519 -t ed25519 -N "" -C "Server-Hostkey"
mv /etc/ssh/sshd_config /etc/ssh/sshd_config.orig
echo "Port $sshport
HostKey /etc/ssh/key_ed25519
HostKeyAlgorithms ssh-ed25519
KexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256@libssh.org
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com
HostbasedAcceptedKeyTypes ssh-ed25519

PermitRootLogin prohibit-password
PasswordAuthentication no
AuthenticationMethods publickey
PubkeyAuthentication yes
#AuthorizedKeysFile     .ssh/authorized_keys

MaxAuthTries 2
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
PermitEmptyPasswords no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp  internal-sftp 
UseDNS no
Compression no
LoginGraceTime 45
ClientAliveCountMax 1
ClientAliveInterval 1800
IgnoreRhosts yes">> /etc/ssh/sshd_config

mv /etc/apt/apt.conf.d/50unattended-upgrades /etc/apt/apt.conf.d/50unattended-upgrades.orig
echo '#
# For defaults settings press CTRL - X (close)
# If you change things  press CTRL - X and CTRL - Y and ENTER (save and close)
# Maybe change Automatic-Reboot-Time ..
#
Unattended-Upgrade::Allowed-Origins {
  "${distro_id}:${distro_codename}";
	"${distro_id}:${distro_codename}-security";
	"${distro_id}ESM:${distro_codename}";
	"${distro_id}:${distro_codename}-updates";
//	"${distro_id}:${distro_codename}-proposed";
//	"${distro_id}:${distro_codename}-backports";
};
Unattended-Upgrade::Package-Blacklist {
};
Unattended-Upgrade::DevRelease "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "01:30";
' >> /etc/apt/apt.conf.d/50unattended-upgrades

echo '
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
' >> /etc/apt/apt.conf.d/20auto-upgrades

nano /etc/apt/apt.conf.d/50unattended-upgrades
#nano /etc/apt/apt.conf.d/20auto-upgrades

sed -i "s@6,18:00@9,23:00@" /lib/systemd/system/apt-daily.timer
sed -i "s@12h@1h@" /lib/systemd/system/apt-daily.timer
sed -i "s@6:00@1:00@" /lib/systemd/system/apt-daily-upgrade.timer

chmod -x /etc/update-motd.d/*
mv /etc/motd /etc/motd.bak


cat << 'EOF' > /etc/update-motd.d/20-25login
#!/bin/bash
systemver=$(grep PRETTY_NAME /etc/os-release | sed 's/PRETTY_NAME="\(.*\)"/\1/' | sed 's/GNU\///' | awk '{print $1, $3}')

echo ""
echo "Hello $(whoami), welcome back to your server:"
echo ""
echo "Hostname  : $(hostname)"
echo "Kernel    : $systemver $(uname -v | awk '{print $4,$5,$6}')"
echo "Uptime    : $(uptime -s) / $(uptime -p)"
echo "CPU       : $(uptime | awk -F'load average: ' '{ print $2 }') load"
echo "RAM       : $(free -h | grep Mem | awk '{print $3 "/" $2}')"
echo "DISK      : $(df -h --total | grep total | awk '{print $3 "/" $2 " (" $5 " used)"}')"
echo "IPv4      : $(hostname -I | awk '{print $1}')"
echo "IPv6      : $(hostname -I | grep -oE '([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}' | head -n 1 || echo 'Not assigned')"
echo ""
if [ -f /var/run/reboot-required ]; then
echo ""
echo "⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠"
echo "INFO      : System upgrade required a reboot"
echo "⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠"
echo ""
fi
EOF
chmod +x /etc/update-motd.d/20-25login

read -p "Do you want to reboot the system? (y/n): " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "Rebooting the system..."
    reboot
else
    echo "Reboot cancelled."
fi
