#!/bin/bash

for interface in $(ls /sys/class/net/)
do
    if ! [[ "$interface" =~ "^(lo|br|bond)" ]]
    then
        if [ "$(cat "/sys/class/net/$interface/operstate")" == "up" ] && [ -r "/sys/class/net/$interface/speed" ]
        then
            speed="$(cat "/sys/class/net/$interface/speed")"

            # if speed is 0 or below, this is probably not a "real"
            # ethernet interface.
            if [ "$speed" -gt "1" ]
            then
                if [ "$speed" -lt "1000" ]
                then
                    voc2alert "error" "interface/$interface" "$interface has less than 1Gbit/s (only $speed Mbit/s)"
                fi

                if [ -r "/sys/class/net/$interface/duplex" ]
                then
                    duplex="$(cat "/sys/class/net/$interface/duplex")"
                    if [ "$duplex" != "full" ]
                    then
                        voc2alert "error" "interface/$interface" "$interface runs in $duplex mode!"
                    fi
                fi
            fi
        fi
    fi
done
