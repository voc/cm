TARGET="${target}"
<%text>
declare -A oids_to_check
oids_to_check[MODULE1]="1.3.6.1.4.1.25506.2.6.1.1.1.1.12.112"
oids_to_check[SENSOR1]="1.3.6.1.4.1.25506.2.6.1.1.1.1.12.118"
oids_to_check[MODULE2]="1.3.6.1.4.1.25506.2.6.1.1.1.1.12.122"
oids_to_check[SENSOR2]="1.3.6.1.4.1.25506.2.6.1.1.1.1.12.128"
oids_to_check[MODULE3]="1.3.6.1.4.1.25506.2.6.1.1.1.1.12.132"
oids_to_check[SENSOR3]="1.3.6.1.4.1.25506.2.6.1.1.1.1.12.138"

declare | grep -i oids_to_check

for key in "${!oids_to_check[@]}"
do
    SNMP_TEMPERATURE="$(snmpget -v2c -cpublic -Ovq "$TARGET" "${oids_to_check[$key]}" 2>/dev/null)"

    if [[ -n "$SNMP_TEMPERATURE" ]]
    then
        if [[ "$SNMP_TEMPERATURE" -ge 80 ]]
        then
            MY_HOSTNAME="$TARGET" voc2alert "error" "temperature/$key" "Temperature is $SNMP_TEMPERATURE°C"
        elif [[ "$SNMP_TEMPERATURE" -ge 75 ]]
        then
            MY_HOSTNAME="$TARGET" voc2alert "warn" "temperature/$key" "Temperature is $SNMP_TEMPERATURE°C"
        fi
    fi
done
</%text>
