groups["minisforuminions"] = {
    'members': {
        'minion1',
        'minion2',
        'minion3',
        'minion4',
        'minion5',
        'minion6',

    },
    'bundles': {
        'samba',
        'zfs',
    },
    'metadata': {
        'apt': {
            'packages': {
                "intel-media-va-driver-non-free": {},
                "firmware-misc-nonfree": {},
            },
        },
        'crs-worker': {
            'number_of_encoding_workers': 2,
            'pin_to_performance': True,
            'separate_vaapi_worker': True,
        },
        'systemd-networkd': {
            'bridges': {
                'br0': {
                    'match': [
                        'enp87s0',
                        'enp90s0',
                        'enp2s0f0',
                        'enp2s0f1',
                    ],
                },
            },
        },
        'users': {
            'voc': {
                'groups': ['render', 'video'],
            },
        },
        'zfs': {
            "datasets": {
                "zroot": {},
                "zroot/ROOT": {},
                "zroot/ROOT/debian": {
                    "mountpoint": "/",
                },
                "zroot/home": {
                    "mountpoint": "/home",
                },
                "zroot/home/root": {
                    "mountpoint": "/root",
                },
                "zroot/var": {},
                "zroot/var/cache": {
                    "mountpoint": "/var/cache",
                },
                "zroot/var/lib": {
                    "mountpoint": "/var/lib",
                },
                "zroot/var/log": {
                    "mountpoint": "/var/log",
                },
            },
            "pools": {
                "zroot": {}
            },
        },

    }
}
