#!/bin/bash

# a CT0, nenastavuje VETH
#volake cudne farby

badParam() {
    echo "Error: 'args' nespravne parametre "
}

msage() {
    echo "Usage: $0 [-h] -c CTID [-ip IPadress]" >&2
}

#ak neboli zadane ziadne paraetre, vypise sa usage
if [ "$#" -eq 0 ]
then
    msage
    exit 1
fi

#Test ci som root
if [ "$UID" -ne 0 ]
then echo "You must be logged in as root" >&2
     exit 1
 fi

if [ ! -f /etc/debian_version ]
then
    echo "You must use debian" >&2
    exit 1
fi

#spracovanie argumentov
while test -n "$1"
do
    case "$1" in
        -h)
            help
            exit 1
            ;;
        -c)
            shift
            if [ -n "$1" ]
                then
                    CTID=$1
                else
                    msage
                    exit 1
                fi
            shift
            ;;
        -ip)
            shift
            if [ -n "$1" ]
            then
                IPadress="$1"
                if [ `echo "$IPadress" | grep -cE '\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?(\.|$)){4}\b'` -eq 0 ]
                then
                    echo "Ip address is not valid" >&2
                    exit 1
                fi
            else
                msage
                exit 1
            fi
            shift
            ;;
        *)
            badParam
            exit 1
            ;;
    esac
done

if [ ! -n "$CTID" ]
then
    echo "Error: 'you must instert CTID'" >&2
    exit 1
fi

#test ci kontajner existuje
if [ `vzlist -a | tr -s " " | cut -d" " -f2 | grep "$CTID" | wc -l` -eq 0 ]
then
    echo "Container doesn't exists" >&2
    exit 1 #chyba kontajner neexistuje
fi


#Treba zapnut presmerovanie portov
routing=`grep "^net.ipv4.ip_forward = 1$" /etc/sysctl.conf | wc -l`
if [ "$routing" -eq 0  ]
then
    echo "ipv4 routing is disabled ... turning on" >&2
    sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf
    sysctl -p /etc/sysctl.conf
fi
unset routing

#kontroloa ci je nacitany modul tun
modulLoaded=`lsmod | grep tun | wc -l`
if [ "$modulLoaded" -eq 0 ]
then
    echo "module tun must be loaded ... loading " >&2
    modprobe tun
fi

#ak kontainer bezi, treba ho stopnut
if [ `vzlist -a | grep "running" | wc -l ` -eq 1 ]
then
    vzctl stop $CTID
fi

#priradime kontajneru potrebne vlastnosti
vzctl set $CTID --devnodes net/tun:rw --save
vzctl set $CTID --devices c:10:200:rw --save
vzctl set $CTID --capability net_admin:on --save

#dalsie zalezitosti treba nastavit pri spustenom kontajneri
vzctl start $CTID
vzctl exec $CTID mkdir -p /dev/net
vzctl exec $CTID mknod /dev/net/tun c 10 200
vzctl exec $CTID chmod 600 /dev/net/tun


if [ ! -n "$IPadress" ]
then
    #pouzivatel nezadal IP, nebudem teda nastavovat veth
    exit 1
fi

#dalej nastavime VETH device na kontajneri
#kontrola ci je nacitany modul vzeth
if [ `lsmod | grep -c vzeth` -eq 0 ]
then
    echo "module vzeth must be loaded ... loading" >&2
    modprobe vzethdev
fi

vzctl set $CTID --netif_add eth0 --save
