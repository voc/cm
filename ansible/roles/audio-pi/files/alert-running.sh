#!/bin/bash
set -e

cd /opt/mqtt
# only call max every n seconds
/opt/mqtt/ratelimit.sh running 290 perl -Mlocal::lib /opt/mqtt/mqttsend.pl INFO streaming process started
