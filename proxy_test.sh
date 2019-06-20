#!/bin/bash
echo " just a test "
echo " read the lines befor running the script "
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


apt update
apt install squid3 apache2-utils -y

inet=$(hostname --ip-address | awk '{print $2}')
echo "-----------------------------------------------------"
read -p "proxy http_port : " -e -i 53128 port
echo "-----------------------------------------------------"
read -p "proxy outgoing_address : " -e -i $inet tcpout
echo "-----------------------------------------------------"
read -p "Username for proxy-loging : " -e -i proxyuser001 user001
echo "-----------------------------------------------------"



touch /etc/squid/passwords
chmod 777 /etc/squid/passwords
htpasswd -c /etc/squid/passwords $user001

#/usr/lib/squid3/basic_ncsa_auth /etc/squid/passwords

mv /etc/squid/squid.conf /etc/squid/squid.conf.original

echo "
http_port $port
dns_v4_first on
cache deny all
forwarded_for delete
request_header_access X-Forwarded-For deny all
request_header_access From deny all
request_header_access Referer deny all
request_header_access User-Agent deny all
tcp_outgoing_address $tcpout
via off
auth_param basic program /usr/lib/squid3/basic_ncsa_auth /etc/squid/passwords
auth_param basic realm proxy
auth_param basic children 5
auth_param basic credentialsttl 60 minutes
acl authenticated proxy_auth REQUIRED
acl GOOD dstdomain .github.com
http_access allow GOOD
http_access allow authenticated
http_access deny all
" >> /etc/squid/squid.conf

nano /etc/squid/squid.conf


ufw allow $port
ufw reload
service squid restart
