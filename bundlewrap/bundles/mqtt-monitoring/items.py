files['/usr/local/sbin/check_system.sh'] = {
    'content_type': 'jinja2',
    'context': {
        'mqtt': node.metadata.get('mqtt-monitoring'),
        'event': node.metadata.get('event'),
    },
    'mode': '0755',
}
directories['/usr/local/sbin/check_system.d'] = {}

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
