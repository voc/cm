groups['alboin'] = {
    'metadata': {
        'apt': {
            'packages': {
                'qemu-guest-agent': {},
            },
        },
        'grub': {
            'cmdline_linux': {
                'net.ifnames': '1',
            },
        },
        'nameservers': [
            '5.1.66.255',
            '185.150.99.255',
            '2001:678:e68:f000::',
            '2001:678:ed0:f000::',
        ],
    },
}

groups['minions-alboin'] = {
    'member_patterns': {
        r'^minion254-\d+$',
    },
    'supergroups': {
        'crs-workers',
        'minions',
        'alboin',
    },
    'bundles': {
        'cifs-client',
    },
    'metadata': {
        'interfaces': {
            'ens18': {
                'gateway4': '10.73.254.201',
            },
        },
        'nameservers': [
            '10.73.254.201',
        ],
        'cifs-client': {
            'mounts': {
                'video': {
                    'create_dir': True,
                    'serverpath': '//10.73.254.112/video',
                    'mount_options': {
                        'ro': None,
                    },
                },
                'video-encoded': {
                    'serverpath': '//10.73.254.112/encoded',
                },
                'video-fuse': {
                    'serverpath': '//10.73.254.112/fuse',
                },
                'video-tmp': {
                    'serverpath': '//10.73.254.112/tmp',
                },
            },
        },
        'crs-worker': {
            'autostart_scripts': {
                'encoding',
            },
            'secrets': {
                'encoding': {
                    'secret': vault.decrypt('encrypt$gAAAAABoDlB2AL8AN7cRoq3wzogBu3GdCVuX4XpUn7krb7fshlxRLZDabD7YTckuWrXxYx3kQBJXUTWIPgWH6LPX8C3PwdZlACaBT-hSfvJZ0J4O0O7P-kwJaIFZnW5hy9gi4F85OGUP'),
                    'token': vault.decrypt('encrypt$gAAAAABoDlBzpSIb1evzwJy2bwyG78b8v5RBCQwDZ60bY5hpOozgTRaGm3KWBZ5paYaRl4cPHTqKSunTqgTXz56UIZqKq7d1kWs0YaSjhzswN-iyPNMGz8Dhz9z1T6S2ytbSp5bPY0zR'),
                },
            },
        },
    },
}

