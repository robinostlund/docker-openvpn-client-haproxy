#!/bin/bash

# create folders
if [ ! -d /data/haproxy ]; then
  mkdir -p /data/haproxy
  chmod -R 0755 /data/haproxy
  #chown -R haproxy:haproxy /data/haproxy
fi

if [ ! -d /run/haproxy ]; then
  mkdir -p /run/haproxy
  chmod -R 0755 /run/haproxy
  #chown -R haproxy:haproxy /run/haproxy
fi

if [ ! -d "/data/haproxy/examples" ]; then
    mkdir /data/haproxy/examples
    cp /root/files/haproxy.cfg.example /data/haproxy/examples/haproxy.cfg.example
fi


# create haproxy config files
if [ ! -f /data/haproxy/haproxy.cfg ]; then
  cp /root/files/haproxy.cfg.example /data/haproxy/haproxy.cfg
  chown -R haproxy:haproxy /data/haproxy/haproxy.cfg
fi

# start haproxy
haproxy -f /data/haproxy/haproxy.cfg -C /data/haproxy
