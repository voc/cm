groups['encoders'] = {
    'member_patterns': {
        r'^encoder.+$',
    },
    'bundles': {
        'rsync',
        'samba',
        'voctocore',
        'voctocore-artwork',
        'voctomix2',
    },
    'metadata': {
        'mqtt-monitoring': {
            'plugins': {
                'raid_mdstat',
            },
        },
        'systemd': {
            'ignore_power_switch': True,
        },
        'users': {
            'voc': {
                'groups': ['video', 'audio'],
            },
        },
    },
}

groups['minions'] = {
    'member_patterns': {
        r'^minion.+$',
    },
}

groups['mixers'] = {
    'member_patterns': {
        r'^mixer.+$',
    },
    'bundles': {
        'mixer-common',
        'voctogui',
        'voctomix2',
    },
    'metadata': {
        'mqtt-monitoring': {
            'plugins': {
                'ac_power',
            },
        },
        'systemd': {
            'ignore_power_switch': True,
        },
    },
}

groups['crs-workers'] = {
    'subgroups': {
        'encoders',
        'minions',
    },
    'bundles': {
        'crs-worker',
        'encoder-common',
    },
    'metadata': {
        'crs-worker': {
            'tracker_url': 'https://tracker.c3voc.de/rpc',
        },
    },
}

groups['tallycom'] = {
    'member_patterns': {
        r'^tallycom.+$',
    },
    'bundles': {
        'voctolight',
        'voctomix2',
    },
}
