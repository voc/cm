import bwkeepass as keepass

defaults = {
    'apt': {
        'packages': {
            'jq': {},
            'mosquitto-clients': {},
        },
    },
    'mqtt-monitoring': {
        'server': keepass.url(['ansible', 'mqtt']),
        'username': keepass.username(['ansible', 'mqtt']),
        'password': keepass.password(['ansible', 'mqtt']),
        'plugins': {
            'disk_space',
            'fans_and_temps',
            'systemd_failed_units',
            'kernel_log',
        },
    },
    'systemd-timers': {
        'timers': {
            'check_system_and_send_mqtt_message': {
                'command': '/usr/local/sbin/check_system.sh',
                'when': 'minutely',
            },
        },
    },
}

if 'minion' not in node.name:
    defaults['mqtt-monitoring']['plugins'].add('load')
    defaults['mqtt-monitoring']['plugins'].add('kernel_throttling')
