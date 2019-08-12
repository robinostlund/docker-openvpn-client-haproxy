#!/bin/sh

set -x

python /usr/bin/openvpn_healthcheck.py >> /data/openvpn/log/openvpn_healthcheck.log
OPENVPN_HEALTHCHECK_EXIT_CODE=$?

exit $OPENVPN_EXIT_CODE
