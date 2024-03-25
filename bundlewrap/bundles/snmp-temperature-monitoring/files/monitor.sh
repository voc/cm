TARGET="${target}"
SNMP_TEMPERATURE="$(${command})"

if [[ -n "$SNMP_TEMPERATURE" ]]
then
    if [[ "$SNMP_TEMPERATURE" -ge 80 ]]
    then
        MY_HOSTNAME="$TARGET" voc2alert "error" "temperature" "Temperature is $SNMP_TEMPERATURE°C"
    elif [[ "$SNMP_TEMPERATURE" -ge 75 ]]
    then
        MY_HOSTNAME="$TARGET" voc2alert "warn" "temperature" "Temperature is $SNMP_TEMPERATURE°C"
    fi
fi
