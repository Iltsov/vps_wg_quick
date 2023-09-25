#!/bin/bash

cd /etc/wireguard

umask 077

SERVER_PRIVKEY=$( wg genkey )
SERVER_PUBKEY=$( echo $SERVER_PRIVKEY | wg pubkey )

echo $SERVER_PUBKEY > ./server_public_warp.key
echo $SERVER_PRIVKEY > ./server_private_warp.key

ENDPOINT="$(curl --ipv4 --connect-timeout 5 --tlsv1.2 --silent 'https://checkip.amazonaws.com')"
if [ -z "${ENDPOINT}" ]; then
    ENDPOINT="$(curl --ipv4 --connect-timeout 5 --tlsv1.3 --silent 'https://icanhazip.com')"
fi
echo $ENDPOINT:1344 > ./endpoint_warp.var

SERVER_IP="10.60.0.1"

echo $SERVER_IP | grep -o -E '([0-9]+\.){3}' > ./vpn_subnet_warp.var

DNS="1.1.1.1"
echo $DNS > ./dns_warp.var

echo 1 > ./last_used_ip_warp.var

WAN_INTERFACE_NAME="$(ip route | grep default | head --lines=1 | cut --delimiter=" " --fields=5)"
# If no NIC is found, exit with an error.
if [ -z "${WAN_INTERFACE_NAME}" ]; then
    echo "Error: Your server's public network interface could not be found."
    exit
fi

echo $WAN_INTERFACE_NAME > ./wan_interface_name_warp.var

cat ./endpoint_warp.var | sed -e "s/:/ /" | while read SERVER_EXTERNAL_IP SERVER_EXTERNAL_PORT

do
cat > ./wg1.conf << EOF
[Interface]
Address = $SERVER_IP
SaveConfig = false
PrivateKey = $SERVER_PRIVKEY
ListenPort = $SERVER_EXTERNAL_PORT
PostUp     = iptables -t nat -A POSTROUTING -o $WAN_INTERFACE_NAME -j MASQUERADE;
PostUp     = ip rule add from 10.60.0.0/24 table default
PostDown   = iptables -t nat -D POSTROUTING -o $WAN_INTERFACE_NAME -j MASQUERADE;
PostDown   = ip rule del from 10.60.0.0/24 table default
EOF
done

systemctl enable wg-quick@wg1



