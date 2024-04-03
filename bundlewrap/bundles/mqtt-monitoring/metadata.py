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
            'systemd_failed_units',
            'kernel_log',
        },
        'plugins_daily': set(),
    },
    'systemd-timers': {
        'timers': {
            'check_system_and_send_mqtt_message': {
                'command': '/usr/local/sbin/check_system.sh',
                'when': 'minutely',
                'environment': {
                    'DAILY_TASK_TIME': str(6+(node.magic_number%3)).rjust(2, '0') + str(node.magic_number%60).rjust(2, '0'),
                },
                'requires': {
                    'network.target',
                },
            },
        },
    },
}

if 'minion' not in node.name:
    defaults['mqtt-monitoring']['plugins'].add('fans_and_temps')
    defaults['mqtt-monitoring']['plugins'].add('kernel_throttling')
    defaults['mqtt-monitoring']['plugins'].add('load')

@metadata_reactor.provides(
    'systemd-timers/timers/check_system_and_send_mqtt_message/environment/MY_HOSTNAME',
)
def hostname(metadata):
    return {
        'systemd-timers': {
            'timers': {
                'check_system_and_send_mqtt_message': {
                    'environment': {
                        'MY_HOSTNAME': metadata.get('hostname'),
                    },
                },
            },
        },
    }
