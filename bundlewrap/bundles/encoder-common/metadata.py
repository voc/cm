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


@metadata_reactor.provides(
    'zfs/datasets',
    'zfs/snapshots/retain_per_dataset',
)
def zfs(metadata):
    if not node.has_bundle('zfs'):
        raise DoNotRunAgain

    slug = metadata.get('event/slug')

    datasets = {
        f'video/{slug}': {},
    }

    for path in (
        'capture',
        'encoded',
        'fuse',
        'intros',
        'tmp',
    ):
        datasets[f'video/{slug}/{path}'] = {
            'mountpoint': f'/video/{path}/{slug}',
            'needed_by': {
                f'directory:/video/{path}/{slug}',
            },
        }

    return {
        'zfs': {
            'datasets': datasets,
            'snapshots': {
                'retain_per_dataset': {
                    f'video/{slug}/{path}': {
                        'hourly': 2,
                        'daily': 0,
                        'weekly': 0,
                        'monthly': 0,
                    } for path in ('capture', 'tmp')
                },
            },
        },
    }
