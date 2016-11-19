#!/bin/sh
### BEGIN INIT INFO
# Provides:          Sends report about new relay
# Required-Start:    $network $remote_fs $syslog
# Required-Stop:     $network $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:
# Short-Description: Sends report about new relay
# Description:       Sends report about new relay
### END INIT INFO

. /lib/lsb/init-functions

if [ x"$1" = x"start" ]
then
	log_begin_msg "Registering relay"

	sleep 10

	ruby /usr/local/sbin/register_relay

	log_end_msg "$?"
fi
