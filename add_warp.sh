#!/usr/bin/env bash

apt install python3-pip -y
pip install httpx
python ./pywarp.py

./wgcf register --accept-tos
read KEY < ./key
WGCF_LICENSE_KEY="$KEY" ./wgcf update
./wgcf generate

Get_WireGuard_Interface_MTU() {
    MTU_Preset=1500
    MTU_Increment=10
    CMD_ping='ping'
    MTU_TestIP_1="1.0.0.1"
    MTU_TestIP_2="9.9.9.9"
    while true; do
        if ${CMD_ping} -c1 -W1 -s$((${MTU_Preset} - 28)) -Mdo ${MTU_TestIP_1} >/dev/null 2>&1 || ${CMD_ping} -c1 -W1 -s$((${MTU_Preset} - 28)) -Mdo ${MTU_TestIP_2} >/dev/null 2>&1; then
            MTU_Increment=1
            MTU_Preset=$((${MTU_Preset} + ${MTU_Increment}))
        else
            MTU_Preset=$((${MTU_Preset} - ${MTU_Increment}))
            if [[ ${MTU_Increment} = 1 ]]; then
                break
            fi
        fi
        if [[ ${MTU_Preset} -le 1360 ]]; then
            MTU_Preset='1360'
            break
        fi
    done
    WireGuard_Interface_MTU=$((${MTU_Preset} - 80))
}

Get_WireGuard_Interface_MTU
WireGuard_Interface_PrivateKey=$(cat ./wgcf-profile.conf | grep ^PrivateKey | cut -d= -f2- | awk '$1=$1')
WireGuard_Interface_Address='172.16.0.2/32'
WireGuard_Peer_PublicKey=$(cat ./wgcf-profile.conf | grep ^PublicKey | cut -d= -f2- | awk '$1=$1')
WireGuard_Peer_AllowedIPs='0.0.0.0/0'
WireGuard_Interface_DNS='1.1.1.1'
WireGuard_Peer_Endpoint='162.159.192.1:2408'
IPv4_addr="$(curl --ipv4 --connect-timeout 5 --tlsv1.2 --silent 'https://checkip.amazonaws.com')"
if [ -z "${IPv4_addr}" ]; then
    IPv4_addr="$(curl --ipv4 --connect-timeout 5 --tlsv1.3 --silent 'https://icanhazip.com')"
fi

cat <<EOF > /etc/wireguard/wgcf.conf
[Interface]
PrivateKey = ${WireGuard_Interface_PrivateKey}
Address = ${WireGuard_Interface_Address}
DNS = ${WireGuard_Interface_DNS}
MTU = ${WireGuard_Interface_MTU}
PostUp = ip -4 rule add from ${IPv4_addr} lookup main prio 18
PostDown = ip -4 rule delete from ${IPv4_addr} lookup main prio 18

[Peer]
PublicKey = ${WireGuard_Peer_PublicKey}
AllowedIPs = ${WireGuard_Peer_AllowedIPs}
Endpoint = ${WireGuard_Peer_Endpoint}
EOF

systemctl enable wg-quick@wgcf
