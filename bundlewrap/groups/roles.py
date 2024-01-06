groups['encoders'] = {
    'member_patterns': {
        r'^encoder.+$',
    },
    'bundles': {
        'mdadm',
        'rsync',
        'samba',
        'voctocore',
        'voctocore-artwork',
        'voctomix2',
    },
    'metadata': {
        'systemd': {
            'ignore_power_switch': True,
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

groups['routers'] = {
    'member_patterns': {
        r'^router.+$',
    },
    'bundles': {
        'bird',
        'generator-routing',
        'generator-s2s',
        'isc-dhcp-server',
        'unbound-with-knot',
    },
}
