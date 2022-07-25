if [ -r "/proc/acpi/ibm/fan" ]
then
    fan_info=$(cat /proc/acpi/ibm/fan)
    fan_speed=$(echo "$fan_info" | awk '/^speed/ {print $2}')
    fan_level=$(echo "$fan_info" | awk '/^level/ {print $2}')

    voc2mqtt -t 'hosts/'$TRUNC_HOSTNAME'/stats/fan_speed' -m $fan_speed
    voc2mqtt -t 'hosts/'$TRUNC_HOSTNAME'/stats/fan_level' -m $fan_level
fi

% for device in sorted(node.metadata.get('thinkfan/hwmon', set())):
voc2mqtt -t 'hosts/'$TRUNC_HOSTNAME'/stats/${device.split('/')[-1]}' -m "$(echo "$(cat ${device}) / 1000" | bc)"
% endfor
