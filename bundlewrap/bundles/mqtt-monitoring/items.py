import bwkeepass as keepass

files['/usr/local/sbin/check_system.sh'] = {
    'content_type': 'jinja2',
    'context': {
        'mqtt': {
            'server': keepass.url(['ansible', 'mqtt']),
            'username': keepass.username(['ansible', 'mqtt']),
            'password': keepass.password(['ansible', 'mqtt']),
        },
        'event': {
            'acronym': 'TODO', # TODO
        },
    },
    'mode': '0755',
}
directories['/usr/local/sbin/check_system.d'] = {}

files['/usr/local/lib/systemd/system/send-mqtt-shutdown.service'] = {
    'triggers': {
        'action:systemd-reload',
    },
}
svc_systemd['send-mqtt-shutdown'] = {
    'needs': {
        'file:/usr/local/lib/systemd/system/send-mqtt-shutdown.service',
    },
}
