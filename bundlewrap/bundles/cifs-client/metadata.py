defaults = {
    'apt': {
        'packages': {
            'cifs-utils': {},
        },
    },
}


@metadata_reactor.provides(
    'cifs-client/mounts'
)
def fill_mount_options(metadata):
    ret = {}
    for mount, data in node.metadata.get('cifs-client/mounts', {}).items():
        ret[mount] = {
            'mount_options': {
                'dir_mode': data.get('mount_options', {}).get('dir_mode', '0755'),
                'file_mode': data.get('mount_options', {}).get('file_mode', '0644'),
                'gid': data.get('group', 'voc'),
                'password': data.get('password', ''),
                'uid': data.get('owner', 'voc'),
            },
            'mountpoint': data.get('mountpoint', '/{}'.format(mount.replace('-', '/'))),
        }

        if data.get('credentials', None):
            ret[mount]['mount_options']['credentials'] = '/etc/cifs-credentials/{}'.format(mount),

    return {
        'cifs-client': {
            'mounts': ret,
        },
    }
