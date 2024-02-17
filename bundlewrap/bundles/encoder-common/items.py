from bundlewrap.exceptions import BundleError

if node.has_bundle('cifs-client'):
    user_group = None
else:
    user_group = 'voc'

event = node.metadata.get('event/slug')

directories[f'/video'] = {
    'owner': user_group,
    'group': user_group,
    'after': {
        'zfs_dataset:',
        'zfs_pool:',
    },
}

for path in (
    'capture',
    'encoded',
    'fuse',
    'intros',
    'tmp',
):
    directories[f'/video/{path}'] = {
        'owner': user_group,
        'group': user_group,
    }

    directories[f'/video/{path}/{event}'] = {
        'before': {
            'bundle:voctocore',
            'bundle:crs-worker',
        },
        'owner': user_group,
        'group': user_group,
    }

directories[f'/video/tmp/{event}/repair'] = {
    'before': {
        'bundle:voctocore',
        'bundle:crs-worker',
    },
    'owner': user_group,
    'group': user_group,
}
