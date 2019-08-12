#!/bin/bash

iptables="/sbin/iptables"
LOCAL_NETWORKS="${LOCAL_NETWORKS:='default'}"
OPENVPN_INTERFACE="openvpn"
OPENVPN_ALLOW_TCP="${OPENVPN_FIREWALL_ALLOW_TCP:='default'}"
OPENVPN_ALLOW_UDP="${OPENVPN_FIREWALL_ALLOW_UDP:='default'}"
OPENVPN_REMOTE_PORTS="${OPENVPN_REMOTE_PORTS:='1194,1195'}"

# flush all chains
$iptables --flush

# allow unlimited traffic on the loopback interface
$iptables -A INPUT -i lo -j ACCEPT
$iptables -A OUTPUT -o lo -j ACCEPT

# set default_in policies
$iptables --policy INPUT DROP
$iptables --policy OUTPUT DROP
$iptables --policy FORWARD DROP

# previously initiated and accepted exchanges bypass rule checking
# allow unlimited outbound traffic
$iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
$iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
$iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# create default out chain
$iptables -F default_out
$iptables -X default_out
$iptables -N default_out
$iptables -I OUTPUT 3 -j default_out

# create openvpn out chain
$iptables -F openvpn_out
$iptables -X openvpn_out
$iptables -N openvpn_out
$iptables -I OUTPUT 3 -j openvpn_out

# create default in chain
$iptables -F default_in
$iptables -X default_in
$iptables -N default_in
$iptables -I INPUT 3 -j default_in

# create openvpn in chain
$iptables -F openvpn_in
$iptables -X openvpn_in
$iptables -N openvpn_in
$iptables -I INPUT 3 -j openvpn_in

# openvpn tcp rules
if [ -z "$OPENVPN_ALLOW_TCP" ]; then
    # allow all incoming ports if OPENVPN_FIREWALL_ALLOW is empty
    $iptables -A openvpn_in -i $OPENVPN_INTERFACE -p tcp -m state --state NEW -j ACCEPT
else
    # only process if string is not equal to default
    if [ "$OPENVPN_ALLOW_TCP" != "default" ]; then
        # Convert string to array
        IFS=',' read -ra FW_RULES <<< "$OPENVPN_ALLOW_TCP"
        for rule in "${FW_RULES[@]}"; do
            $iptables -A openvpn_in -i $OPENVPN_INTERFACE -p tcp --dport $rule -m state --state NEW -j ACCEPT
        done
    fi
fi

# openvpn udp rules
if [ -z "$OPENVPN_ALLOW_UDP" ]; then
    # allow all incoming ports if OPENVPN_FIREWALL_ALLOW is empty
    $iptables -A openvpn_in -i $OPENVPN_INTERFACE -p udp -m state --state NEW -j ACCEPT
else
    # only process if string is not equal to default
    if [ "$OPENVPN_ALLOW_UDP" != "default" ]; then
        # Convert string to array
        IFS=',' read -ra FW_RULES <<< "$OPENVPN_ALLOW_UDP"
        for rule in "${FW_RULES[@]}"; do
            $iptables -A openvpn_in -i $OPENVPN_INTERFACE -p udp --dport $rule -m state --state NEW -j ACCEPT
        done
    fi
fi

$iptables -A openvpn_out -o $OPENVPN_INTERFACE -m state --state NEW -j ACCEPT                   # allow all outgoing openvpn

# eth0 rules
$iptables -A default_out -o eth0 -p udp --dport 53 -m state --state NEW -j ACCEPT               # allow dns
$iptables -A default_out -o eth0 -p tcp --dport 53 -m state --state NEW -j ACCEPT               # allow dns
$iptables -A default_out -o eth0 -p icmp --icmp-type 8 -m state --state NEW -j ACCEPT           # allow ping

IFS=',' read -ra FW_RULES <<< "$OPENVPN_REMOTE_PORTS"
for rule in "${FW_RULES[@]}"; do
    $iptables -A default_out -o eth0 -p udp --dport $rule -m state --state NEW -j ACCEPT
    $iptables -A default_out -o eth0 -p tcp --dport $rule -m state --state NEW -j ACCEPT
done

DOCKER_GW="$(ip route |awk '/default/ {print $3}')"
IFS=',' read -ra NETWORKS <<< "$LOCAL_NETWORKS"
for network in "${NETWORKS[@]}"; do
    $iptables -A default_out -o eth0 -d $network -m state --state NEW -j ACCEPT
    ip route | grep -q "$network" || ip route add to $network via $DOCKER_GW dev eth0
done

# drop all other traffic, MUST BE LAST!
$iptables -A INPUT -j DROP
$iptables -A OUTPUT -j DROP
$iptables -A FORWARD -j DROP
