files['/usr/local/sbin/voc2alert'] = {
    'mode': '0755',
}

files['/usr/local/sbin/voc2mqtt'] = {
    'content_type': 'mako',
    'context': {
        'mqtt': node.metadata.get('mqtt-monitoring'),
    },
    'mode': '0755',
}

files['/usr/local/sbin/alert_shutdown.sh'] = {
    'mode': '0755',
}

files['/usr/local/sbin/check_system.sh'] = {
    'mode': '0755',
}

files['/usr/local/sbin/check_system_daily.sh'] = {
    'mode': '0755',
}

directories['/usr/local/sbin/check_system.d'] = {
    'purge': True,
}

directories['/usr/local/sbin/check_system_daily.d'] = {
    'purge': True,
}

files['/usr/local/lib/systemd/system/send-mqtt-shutdown.service'] = {
    'content_type': 'mako',
    'triggers': {
        'action:systemd-reload',
    },
}

svc_systemd['send-mqtt-shutdown'] = {
    'needs': {
        'file:/usr/local/lib/systemd/system/send-mqtt-shutdown.service',
    },
}

for plugin in node.metadata.get('mqtt-monitoring/plugins', set()):
    files[f'/usr/local/sbin/check_system.d/{plugin}.sh'] = {
        'source': f'plugins/{plugin}.sh',
        'mode': '0755',
    }

for plugin in node.metadata.get('mqtt-monitoring/plugins_daily', set()):
    files[f'/usr/local/sbin/check_system_daily.d/{plugin}.sh'] = {
        'source': f'plugins/{plugin}.sh',
        'mode': '0755',
    }
