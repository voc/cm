from bundlewrap.exceptions import BundleError

event = node.metadata.get('event/slug')

cifs_mountpoints = {
    v['mountpoint'].rstrip('/')
    for v in node.metadata.get('cifs-client/mounts', {}).values()
}

if '/video' not in cifs_mountpoints:
    directories[f'/video'] = {
        'owner': 'voc',
        'group': 'voc',
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
        if f'/video/{path}' in cifs_mountpoints:
            continue

        directories[f'/video/{path}'] = {
            'owner': 'voc',
            'group': 'voc',
        }

        directories[f'/video/{path}/{event}'] = {
            'before': {
                'bundle:voctocore',
                'bundle:crs-worker',
            },
            'owner': 'vpc',
            'group': 'voc',
        }

    if '/video/tmp' not in cifs_mountpoints:
        directories[f'/video/tmp/{event}/repair'] = {
            'before': {
                'bundle:voctocore',
                'bundle:crs-worker',
            },
            'owner': user_group,
            'group': user_group,
        }
