#!/bin/sh

check_cert () {
  res="$(/usr/lib/nagios/plugins/check_http -H {{ domain }} -C 20,13)"
  if [ "0" -ne "$?" ]; then
    send_mqtt_message "error" "system/cert/${TRUNC_HOSTNAME}" "<red>$(echo "${res}" | tr -d '\r\n')</red>"
  fi
  debug_output "cert" "{{ domain }}" "${res}"
}

check_cert
