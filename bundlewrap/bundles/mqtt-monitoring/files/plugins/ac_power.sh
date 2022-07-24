if [ -r "/sys/class/power_supply/AC/online" ]
then
    ac_online=$(cat /sys/class/power_supply/AC/online)
    if [ -r "/sys/class/power_supply/BAT0/capacity" ]
    then
      bat0_capacity=$(cat /sys/class/power_supply/BAT0/capacity)
    else
      bat0_capacity="-1"
    fi

    voc2mqtt -t 'hosts/'$TRUNC_HOSTNAME'/stats/BAT0_capacity' -m $bat0_capacity
    voc2mqtt -t 'hosts/'$TRUNC_HOSTNAME'/stats/ac_online' -m $ac_online

    if [ "0" -eq "$ac_online" ] && [ "$bat0_capacity" -le 30 ]
    then
        send_mqtt_message "error" "system/power/${TRUNC_HOSTNAME}" "<red>AC power offline! Battery $bat0_capacity % left.</red>"
    fi
fi
