#!/bin/bash

# We read from the input parameter the name of the client
if [ -z "$1" ]
  then
    read -p "Enter VPN user name: " USERNAME
    if [ -z $USERNAME ]
      then
      echo "[#]Empty VPN user name. Exit"
      exit 1;
    fi
  else USERNAME=$1
fi

cd /etc/wireguard/

read DNS < ./dns_warp.var
read ENDPOINT < ./endpoint_warp.var
read VPN_SUBNET < ./vpn_subnet_warp.var
ALLOWED_IP="0.0.0.0/0"

# Go to the wireguard directory and create a directory structure in which we will store client configuration files
mkdir -p ./clients
cd ./clients
mkdir ./$USERNAME
cd ./$USERNAME
umask 077

CLIENT_PRESHARED_KEY=$( wg genpsk )
CLIENT_PRIVKEY=$( wg genkey )
CLIENT_PUBLIC_KEY=$( echo $CLIENT_PRIVKEY | wg pubkey )

read SERVER_PUBLIC_KEY < /etc/wireguard/server_public_warp.key

# We get the following client IP address
read OCTET_IP < /etc/wireguard/last_used_ip_warp.var
OCTET_IP=$(($OCTET_IP+1))
echo $OCTET_IP > /etc/wireguard/last_used_ip_warp.var

CLIENT_IP="$VPN_SUBNET$OCTET_IP/32"

# Create a blank configuration file client
cat > /etc/wireguard/clients/$USERNAME/$USERNAME-warp.conf << EOF
[Interface]
PrivateKey = $CLIENT_PRIVKEY
Address = $CLIENT_IP
DNS = $DNS
MTU = 1420


[Peer]
PublicKey = $SERVER_PUBLIC_KEY
PresharedKey = $CLIENT_PRESHARED_KEY
AllowedIPs = $ALLOWED_IP
Endpoint = $ENDPOINT
EOF

# Add new client data to the Wireguard configuration file
cat >> /etc/wireguard/wg1.conf << EOF

# $USERNAME
[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
PresharedKey = $CLIENT_PRESHARED_KEY
AllowedIPs = $CLIENT_IP
EOF

# Restart Wireguard
systemctl restart wg-quick@wg1

# Show QR config to display
qrencode -t ansiutf8 < ./$USERNAME-warp.conf

# Show config file
echo "# Display $USERNAME-warp.conf"
echo
cat ./$USERNAME-warp.conf

# Save QR config to png file
#qrencode -t png -o ./$USERNAME.png < ./$USERNAME.conf
