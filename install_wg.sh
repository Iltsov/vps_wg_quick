#!/bin/bash

apt update
apt install wireguard qrencode -y


NET_FORWARD="net.ipv4.ip_forward=1"
sysctl -w  ${NET_FORWARD}
sed -i "s:#${NET_FORWARD}:${NET_FORWARD}:" /etc/sysctl.conf

cd /etc/wireguard

umask 077

SERVER_PRIVKEY=$( wg genkey )
SERVER_PUBKEY=$( echo $SERVER_PRIVKEY | wg pubkey )

echo $SERVER_PUBKEY > ./server_public.key
echo $SERVER_PRIVKEY > ./server_private.key

ENDPOINT="$(curl --ipv4 --connect-timeout 5 --tlsv1.2 --silent 'https://checkip.amazonaws.com')"
if [ -z "${ENDPOINT}" ]; then
    ENDPOINT="$(curl --ipv4 --connect-timeout 5 --tlsv1.3 --silent 'https://icanhazip.com')"
fi
echo $ENDPOINT:1433 > ./endpoint.var

SERVER_IP="10.50.0.1"

echo $SERVER_IP | grep -o -E '([0-9]+\.){3}' > ./vpn_subnet.var

DNS="1.1.1.1"
echo $DNS > ./dns.var

echo 1 > ./last_used_ip.var

WAN_INTERFACE_NAME="$(ip route | grep default | head --lines=1 | cut --delimiter=" " --fields=5)"
# If no NIC is found, exit with an error.
if [ -z "${WAN_INTERFACE_NAME}" ]; then
    echo "Error: Your server's public network interface could not be found."
    exit
fi

echo $WAN_INTERFACE_NAME > ./wan_interface_name.var

cat ./endpoint.var | sed -e "s/:/ /" | while read SERVER_EXTERNAL_IP SERVER_EXTERNAL_PORT

do
cat > ./wg0.conf.def << EOF
[Interface]
Address = $SERVER_IP
SaveConfig = false
PrivateKey = $SERVER_PRIVKEY
ListenPort = $SERVER_EXTERNAL_PORT
PostUp   = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $WAN_INTERFACE_NAME -j MASQUERADE;
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $WAN_INTERFACE_NAME -j MASQUERADE;
EOF
done

cp -f ./wg0.conf.def ./wg0.conf

systemctl enable wg-quick@wg0



