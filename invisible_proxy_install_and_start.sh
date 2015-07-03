#!/bin/sh
#
#
#	All credits go to Security Compass
#	For more information: http://labs.securitycompass.com/appsec-2/mobile/wireless-gateway-transparent-proxy-for-mobile-security-assessments/
#
#	Tip:
#		- If you're having issues try restarting your system, and re-running the script
#		- Ensure the configuration file is in the same directory
#
#

# This script requires privileges to run
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

apt-get install hostapd dnsmasq;

echo "Interface with internet connectivity (e.g. eth0): "
read iInf
echo "Wireless interface (e.g. wlan0): "
read wInf
sed -i s/interface=[a-zA-Z0-9]*/interface=$wInf/g invisible_proxy_configuration.conf
echo "Stopping network manager ..."
service network-manager stop
echo "Stopping dnsmasq ..."
service dnsmasq stop
echo "Bringing down wireless interface ..."
ifconfig $wInf down
echo "Starting hostapd ..."
hostapd -dd -B ./invisible_proxy_configuration.conf
echo "Configuring wireless interface ..."
ifconfig $wInf 10.10.0.1 netmask 255.255.255.0
echo "Starting dnsmasq as DHCP server ..."
dnsmasq --no-hosts --interface $wInf --except-interface=lo --listen-address=10.10.0.1 --dhcp-range=10.10.0.10,10.10.0.50,60m --dhcp-option=option:router,10.10.0.1 --dhcp-lease-max=25 --pid-file=/var/run/nm-dnsmasq-wlan.pid
echo "Stopping firewall and allowing everyone ..."
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
echo "Enabling NAT ..."
iptables -t nat -A POSTROUTING -o $iInf -j MASQUERADE
echo "Enabling IP forwarding ..."
echo 1 > /proc/sys/net/ipv4/ip_forward
echo "Wireless gateway setup is complete"
echo 'Transparent Proxy Port (i.e. the port burp is running on):'
read toPort
iptables -t nat -A PREROUTING -i $wInf -p tcp --dport 80 -j REDIRECT --to-ports $toPort
iptables -t nat -A PREROUTING -i $wInf -p tcp --dport 443 -j REDIRECT --to-ports $toPort
