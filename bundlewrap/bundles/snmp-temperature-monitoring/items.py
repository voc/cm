# the command should output the temperature in degrees celsius, or nothing
# if the command failed
for target_type, get_command in {
    'routeros': """echo "$(snmpget -v2c -cpublic -Ovq "$TARGET" "1.3.6.1.4.1.14988.1.1.3.11.0" 2>/dev/null)/10" | bc 2>/dev/null""",
}.items():
    for target in node.metadata.get(f'snmp-temperature-monitoring/{target_type}', set()):
        files[f'/usr/local/sbin/check_system.d/snmp_temperature_monitoring_{target}.sh'] = {
            'source': 'monitor.sh',
            'content_type': 'mako',
            'context': {
                'target': target,
                'command': get_command,
            },
            'mode': '0755',
        }
