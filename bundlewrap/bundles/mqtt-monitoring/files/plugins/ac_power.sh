if [ -r "/sys/class/power_supply/AC/online" ]
then
    ac_online=$(cat /sys/class/power_supply/AC/online)

    for battery in /sys/class/power_supply/BAT*
    do
        identifier="$(basename "$battery")"

        if [ -r "$battery/capacity" ]
        then
          capacity="$(cat "$battery/capacity")"
        else
          capacity="-1"
        fi

        voc2mqtt -t 'hosts/'$TRUNC_HOSTNAME'/stats/'$identifier'_capacity' -m $capacity
        voc2mqtt -t 'hosts/'$TRUNC_HOSTNAME'/stats/ac_online' -m $ac_online

        if [ "0" -eq "$ac_online" ] && [ "$capacity" -le 30 ]
        then
            send_mqtt_message "error" "system/power/${TRUNC_HOSTNAME}/$identifier" "<red>AC power offline! Battery $identifier $capacity % left.</red>"
        fi
    done
fi
