#!/bin/bash

for interface in $(ls /sys/class/net/)
do
    if ! [[ "$interface" =~ "^(lo|br|bond)" ]] && [ -z "$HYPERVISOR" ]
    then
        if [ "$(cat "/sys/class/net/$interface/operstate")" == "up" ]
        then
            if [ -r "/sys/class/net/$interface/speed" ]
            then
                speed="$(cat "/sys/class/net/$interface/speed")"
                if [ "$speed" -lt "1000" ]
                then
                    send_mqtt_message "error" "system/interface/$TRUNC_HOSTNAME/$interface" "$interface has less than 1Gbit/s (only $speed Mbit/s)"
                fi
                debug_output "$interface" "speed" "$speed"
            fi

            if [ -r "/sys/class/net/$interface/duplex" ]
            then
                duplex="$(cat "/sys/class/net/$interface/duplex")"
                if [ "$duplex" != "full" ]
                then
                    send_mqtt_message "error" "system/interface/$TRUNC_HOSTNAME/$interface" "$interface runs in $duplex mode!"
                fi
                debug_output "$interface" "duplex" "$duplex"
            fi
        fi
    fi
done
