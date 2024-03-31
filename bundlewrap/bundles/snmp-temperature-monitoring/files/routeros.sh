TARGET="${target}"
SNMP_TEMPERATURE="$(echo "$(snmpget -v2c -cpublic -Ovq "$TARGET" "1.3.6.1.4.1.14988.1.1.3.11.0" 2>/dev/null)/10" | bc 2>/dev/null)"

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
