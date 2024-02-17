groups['servercase'] = {
    'members': {
        'router200',
        'storage',
    },
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
    },
}

groups['minions-servercase'] = {
    'member_patterns': {
        r'^minion200-\d+$',
    },
    'supergroups': {
        'crs-workers',
        'minions',
        'servercase',
    },
    'bundles': {
        'cifs-client',
    },
    'metadata': {
        'interfaces': {
            'ens18': {
                'gateway4': '10.73.0.254',
            },
        },
        'cifs-client': {
            'mounts': {
                'video': {
                    'serverpath': '//storage.lan.c3voc.de/video',
                    'mount_options': {
                        'ro': None,
                    },
                },
                'video-encoded': {
                    'serverpath': '//storage.lan.c3voc.de/encoded',
                },
                'video-fuse': {
                    'serverpath': '//storage.lan.c3voc.de/fuse',
                },
                'video-tmp': {
                    'serverpath': '//storage.lan.c3voc.de/tmp',
                },
            },
        },
        'crs-worker': {
            'autostart_scripts': {
                'encoding',
            },
            'secrets': {
                'encoding': {
                    'secret': keepass.password(['ansible', 'worker-groups', 'minions-servercase']),
                    'token': keepass.username(['ansible', 'worker-groups', 'minions-servercase']),
                },
            },
        },
    },
}
