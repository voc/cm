groups['froscon-servers'] = {
    'members': {
        'froscon-storage',
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

groups['froscon-minions-servercase'] = {
    'member_patterns': {
        r'^minion128-\d+$',
    },
    'supergroups': {
        'crs-workers',
        'minions',
        'froscon-servers',
    },
    'bundles': {
        'cifs-client',
    },
    'metadata': {
        'interfaces': {
            'eth0': {
                'gateway4': '10.73.128.201',
            },
        },
        'cifs-client': {
            'mounts': {
                'video': {
                    'serverpath': '//10.73.128.101/video',
                    'mount_options': {
                        'ro': None,
                    },
                },
                'video-encoded': {
                    'serverpath': '//10.73.128.101/encoded',
                },
                'video-fuse': {
                    'serverpath': '//10.73.128.101/fuse',
                },
                'video-tmp': {
                    'serverpath': '//10.73.128.101/tmp',
                },
            },
        },
        'crs-worker': {
            'secrets': {
                'encoding': {
                    'secret': keepass.password(['ansible', 'worker-groups', 'minions-servercase']),
                    'token': keepass.username(['ansible', 'worker-groups', 'minions-servercase']),
                },
            },
        },
    },
}
