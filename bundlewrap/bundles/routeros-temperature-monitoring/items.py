for target in node.metadata.get('routeros-temperature-monitoring/targets', set()):
    files[f'/usr/local/sbin/check_system.d/routeros_temperature_monitoring_{target}.sh'] = {
        'source': 'monitor.sh',
        'content_type': 'mako',
        'context': {
            'target': target,
        },
        'mode': '0755',
    }
