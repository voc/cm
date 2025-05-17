defaults = {
    'apt': {
        'packages': {
            'rename': {},
        },
    },
    'event': {
        'slug': 'XYZ',
    },
    'encoder-common': {
        'zfs-dataset-base': 'video',
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
        'encoder-common/zfs-dataset-base',
)
def dataset_Base(metadata):
    if node.in_group('minisforuminions'):
        return {
            'encoder-common': {
                'zfs-dataset-base': 'zroot',
            },
        }
    else:
        return {}

@metadata_reactor.provides(
    'zfs/datasets',
    'zfs/snapshots/retain_per_dataset',
)
def zfs(metadata):
    if not node.has_bundle('zfs'):
        raise DoNotRunAgain

    slug = metadata.get('event/slug')
    root_ds = metadata.get('encoder-common/zfs-dataset-base')

    datasets = {
        f'{root_ds}/{slug}': {},
    }

    for path in (
        'capture',
        'encoded',
        'fuse',
        'intros',
        'tmp',
    ):
        datasets[f'{root_ds}/{slug}/{path}'] = {
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
                    f'{root_ds}/{slug}/{path}': {
                        'hourly': 2,
                        'daily': 0,
                        'weekly': 0,
                        'monthly': 0,
                    } for path in ('capture', 'tmp')
                },
            },
        },
    }
