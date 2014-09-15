#!/bin/bash

if [ "$#" -lt 2 ]
then
    echo "Usage: $0 CTID IPADDRESS" >&2
    exit 1
fi

CTID=$1
IPadress=$2

if [ `lsmod | grep -c vzeth` -eq 0 ]
then
    echo "module vzeth must be loaded ... loading" >&2
    modprobe vzethdev
fi

if [ `vzlist "$CTID" | grep -c running` -eq 0 ]
then
    echo "Container is not running, we must start it" >&2
    vzctl start "$CTID"
fi

vzctl set $CTID --netif_add eth0 --save

ifconfig veth"$CTID".0 0
echo 1 > /proc/sys/net/ipv4/conf/veth"$CTID".0/forwarding
echo 1 > /proc/sys/net/ipv4/conf/veth"$CTID".0/proxy_arp
echo 1 > /proc/sys/net/ipv4/conf/eth0/forwarding
echo 1 > /proc/sys/net/ipv4/conf/eth0/proxy_arp

vzctl exec $CTID /sbin/ifconfig eth0 0
vzctl exec $CTID /sbin/ip addr add $IPadress dev eth0
vzctl exec $CTID /sbin/route del default
vzctl exec $CTID /sbin/ip route add default dev eth0

route del $IPadress
ip route add $IPadress dev veth"$CTID".0

