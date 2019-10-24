#!/bin/bash
set -e

cd /opt/mqtt
# only call max every n seconds
/opt/mqtt/ratelimit.sh failed 300 perl -Mlocal::lib /opt/mqtt/mqttsend.pl ERROR streaming process failed, trying to restart
