import bwkeepass as keepass

defaults = {
    'apt': {
        'packages': {
            'curl': {},
            'libxml2-utils': {},
        },
    },
    'systemd-timers': {
        'timers': {
            'update_schedule_and_overlays': {
                'command': '/usr/local/bin/update-schedule-and-overlays',
                'when': '*:0/10',
                'requires': {
                    'network-online.target',
                },
            },
        },
    },
}
