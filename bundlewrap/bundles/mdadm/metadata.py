defaults = {
    'apt': {
        'packages': {
            'mdadm': {},
        },
    },
    'mqtt-monitoring': {
        'plugins': {
            'raid_mdstat',
        },
    },
    'systemd-timers': {
        'timers': {
            'mdadm_checkarray': {
                'command': '/usr/share/mdadm/checkarray --cron --all --idle',
                # early morning, so the chance of events happening at
                # that time is very low
                'when': 'Sun 06:00:00 UTC',
            },
        },
    },
}
