#!/bin/bash

MAINPID="$1"
sleep 3
if ( /bin/kill -0 "$MAINPID" &> /dev/null ); then
  /opt/mqtt/alert-running.sh
else
  /opt/mqtt/alert-failed.sh
fi

# don't cause another failure just because of the script
exit 0
