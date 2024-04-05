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
                    'serverpath': '//10.73.200.24/video',
                    'mount_options': {
                        'ro': None,
                    },
                },
                'video-encoded': {
                    'serverpath': '//10.73.200.24/encoded',
                },
                'video-fuse': {
                    'serverpath': '//10.73.200.24/fuse',
                },
                'video-tmp': {
                    'serverpath': '//10.73.200.24/tmp',
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
