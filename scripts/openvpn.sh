#!/usr/bin/env bash

OPENVPN_DIR=/data/openvpn
OPENVPN_CONFIG=openvpn.conf
OPENVPN_PID_FOLDER=/var/run/openvpn
OPENVPN_PID_FILE=openvpn.pid

if [ ! -c /dev/net/tun ]; then
    mknod /dev/net/tun c 10 200
    chmod 600 /dev/net/tun
fi

# create folders
if [ ! -d "/data/openvpn/log" ]; then
    mkdir -p /data/openvpn/log
fi

if [ ! -d "$OPENVPN_PID_FOLDER" ]; then
    mkdir -p $OPENVPN_PID_FOLDER
fi

if [ ! -d "/data/openvvpn/examples" ]; then
    mkdir /data/openvpn/examples
    cp /root/files/credentials.example /data/openvpn/examples/credentials.example
    cp /root/files/openvpn.conf.example /data/openvpn/examples/openvpn.conf.example
fi

# apply iptables rules
/usr/bin/iptables.sh

# start openvpn
openvpn --cd $OPENVPN_DIR --config $OPENVPN_CONFIG --writepid $OPENVPN_PID_FOLDER/$OPENVPN_PID_FILE --dev openvpn --dev-type tun --log /data/openvpn/log/openvpn.log
OPENVPN_EXIT_CODE=$?

# route all traffic through openvpn
#sleep 20
#IP=`/sbin/ifconfig $OVPN_INTERFACE | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}'`
#ip route replace 0.0.0.0/0 via $IP

# little time to ensure the vpn connection is up
sleep 10

# change dns to provided (or default) one
#echo "nameserver 46.227.67.134" > /etc/resolv.conf
#echo "nameserver 192.165.9.158" >> /etc/resolv.conf
#chattr +i /etc/resolv.conf

exit $OPENVPN_EXIT_CODE