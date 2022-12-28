defaults = {
    'apt': {
        'packages': {
            'rename': {},
        },
    },
    'event': {
        'slug': 'XYZ',
    },
    'rsync': {
        'shares': {
            'video': {
                'path': '/video',
            },
        },
    },
    'samba': {
        'shares': {
            'video': {
                'path': '/video',
                'writable': False,
            },
            'fuse': {
                'path': '/video/fuse',
            },
            'tmp': {
                'path': '/video/tmp',
            },
            'encoded': {
                'path': '/video/encoded',
            },
        },
    },
    'sysctl': {
        'options': {
            'vm.swappiness': '5',
        },
    },
}
