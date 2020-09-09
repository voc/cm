#!/bin/sh

check_letsencrypt () {
  res="$(/usr/lib/nagios/plugins/check_http -H {{ domain }} -C 20,13)"
  if [ "0" -ne "$?" ]; then
    send_mqtt_message "error" "system/letsencrypt/${TRUNC_HOSTNAME}" "<red>${res}</red>"
  fi
  debug_output "letsencrypt" "${res}"
}

check_letsencrypt

exit 0