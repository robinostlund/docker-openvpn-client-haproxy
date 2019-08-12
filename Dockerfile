FROM alpine
MAINTAINER Robin Ostlund <me@robinostlund.name>

# Install openvpn
RUN apk --no-cache --no-progress upgrade && \
    apk --no-cache --no-progress add bash curl ip6tables iptables openvpn shadow tini supervisor fping haproxy && \
    addgroup -S vpn && \
    rm -rf /tmp/* && \
    mkdir /root/files

COPY supervisord/supervisord.conf /etc/supervisor/supervisord.conf
COPY scripts/openvpn.sh /usr/bin/openvpn.sh
COPY scripts/openvpn_healthcheck.sh /usr/bin/openvpn_healthcheck.sh
COPY scripts/openvpn_healthcheck.py /usr/bin/openvpn_healthcheck.py
COPY scripts/haproxy.sh /usr/bin/haproxy.sh
COPY scripts/iptables.sh /usr/bin/iptables.sh
COPY examples/credentials.example /root/files/credentials.example
COPY examples/openvpn.conf.example /root/files/openvpn.conf.example
COPY examples/haproxy.cfg.example /root/files/haproxy.cfg.example

RUN chmod +x /usr/bin/openvpn.sh && \
    chmod +x /usr/bin/openvpn_healthcheck.sh && \
    chmod +x /usr/bin/haproxy.sh && \
    chmod +x /usr/bin/iptables.sh


HEALTHCHECK --interval=60s --timeout=15s --start-period=120s \
             CMD curl -L 'https://api.ipify.org'

VOLUME ["/data"]

ENTRYPOINT ["/sbin/tini", "--", "/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
