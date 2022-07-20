#!/bin/bash

if systemctl is-active --quiet voctomix2-voctocore
then
    if ! systemctl is-active --quiet voctomix2-recording-sink
    then
        send_mqtt_message "error" "recording/${node.name}" "voc2mix running, but recording-sink not!"
    else
        message=$(perl /usr/local/sbin/check_system.d/check_recording.pl "/video/capture/${event['slug']}/")
        return_code="$?"

        if [ $return_code -eq 2 ]
        then
            send_mqtt_message "error" "recording/${node.name}" "$message /video/capture/${event['slug']}/"
        fi

        debug_output "recording" $message $return_code
    fi
fi
