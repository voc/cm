#!/bin/bash

if systemctl is-active --quiet voctomix2-voctocore
then
    if ! systemctl is-active --quiet voctomix2-recording-sink
    then
        voc2alert "error" "recording" "voc2mix running, but recording-sink not!"
    else
        message=$(perl /usr/local/sbin/check_system.d/check_recording.pl "/video/capture/${event['slug']}/")
        return_code="$?"

        if [ $return_code -eq 2 ]
        then
            voc2core "error" "recording" "$message /video/capture/${event['slug']}/"
        fi
    fi
fi
