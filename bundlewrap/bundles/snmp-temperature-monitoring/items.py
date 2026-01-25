# the command should output the temperature in degrees celsius, or nothing
# if the command failed
for target_type in ('routeros', 'comware5'):
    for target in node.metadata.get(('snmp-temperature-monitoring', target_type), set()):
        files[f'/usr/local/sbin/check_system.d/snmp_temperature_monitoring_{target}.sh'] = {
            'source': f'{target_type}.sh',
            'content_type': 'mako',
            'context': {
                'target': target,
            },
            'mode': '0755',
        }
