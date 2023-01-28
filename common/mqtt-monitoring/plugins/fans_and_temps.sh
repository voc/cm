if [ -r "/proc/acpi/ibm/fan" ]
then
    voc2mqtt -t "$PER_HOST_TOPIC/stats/fan_level" -m "$(awk '/^level/ {print $2}' /proc/acpi/ibm/fan)"
fi

for i in $(find /sys/devices/platform/ -iname 'temp*_input')
do
    label_filename="$(echo $i | sed 's/input/label/')"
    crit_filename="$(echo $i | sed 's/input/crit/')"
    if [ -r "$label_filename" ]
    then
        label="$(cat "$label_filename" | sed 's/\s\+/_/g')"
        voc2mqtt -t "$PER_HOST_TOPIC/stats/temp_${label}" -m "$(echo "$(cat "$i") / 1000" | bc)"
    else
        label=""
        voc2mqtt -t "$PER_HOST_TOPIC/stats/$(basename $i)" -m "$(echo "$(cat "$i") / 1000" | bc)"
    fi

    if [ -r "$crit_filename" ] && [ -n "$label" ]
    then
        current="$(cat "$i")"
        critical="$(cat "$crit_filename")"

        if [ "${critical}" -gt 1 ] && [ $(echo "${current} > (${critical}*0.95)" | bc) -eq "1" ]
        then
            voc2alert "error" "temp/${label}" "temperature exceeds threshold (currently at $(echo "${current}/1000" | bc)°C, critical at $(echo "${critical}/1000" | bc)°C)</red>"
        fi
    fi
done

for i in $(find /sys/devices/platform/ -iname 'fan*_input')
do
    label_filename="$(echo $i | sed 's/input/label/')"
    if [ -r "$label_filename" ]
    then
        label="fan_$(cat "$label_filename" | sed 's/\s\+/_/g')"
    else
        label="$(basename $i)"
    fi

    voc2mqtt -t "$PER_HOST_TOPIC/stats/$label" -m "$(cat "$i")"
done
