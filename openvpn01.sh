#!/bin/bash
#tento skript sluzi na instalacia sluzby OpenVPN
#pre nainstalovanie vo vnutri kontaineru ju spustite pomocou prislusneho prikazu vzctl

#kontrola ze ci je k dispozicii tun device

if [ -c /dev/net/tun ]
then
    echo "You must setup TUN device" >&2
    exit 1
fi

#instalacia za pouzitia prikazu apt, pre istotu update
apt-get update
apt-get install openvpn

#po instalacii je potrebne zkopirovat zlozky easy-rsa na nove miesto
mkdir /etc/openvpn/easy-rsa
cp -pr /usr/share/doc/openvpn/examples/easy-rsa/2.0/ /etc/openvpn/easy-rsa/2.0/


