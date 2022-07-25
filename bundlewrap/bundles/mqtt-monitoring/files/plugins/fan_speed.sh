if [ -r "/proc/acpi/ibm/fan" ]
then
    voc2mqtt -t 'hosts/'$TRUNC_HOSTNAME'/stats/fan_level' -m "$(awk '/^level/ {print $2}' /proc/acpi/ibm/fan)"
fi

for i in $(find /sys/devices/platform/ -iname 'temp*_input')
do
    label_filename="$(echo $i | sed 's/input/label/')"
    if [ -r "$label_filename" ]
    then
        label="temp_$(cat "$label_filename" | sed 's/\s\+/_/g')"
    else
        label="$(basename $i)"
    fi

    voc2mqtt -t 'hosts/'$TRUNC_HOSTNAME'/stats/'$label -m "$(echo "$(cat "$i") / 1000" | bc)"
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

    voc2mqtt -t 'hosts/'$TRUNC_HOSTNAME'/stats/'$label -m "$(cat "$i")"
done
