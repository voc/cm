defaults = {
    'apt': {
        'packages': {
            "cifs-utils": {},
        },
    },
}


@metadata_reactor.provides(
    'cifs-client/mounts'
)
def fill_mount_options(metadata):
    ret = {
        'cifs-client': {
            'mounts': {},
        },
    }
    for mount, data in node.metadata.get('cifs-client', {}).get('mounts', {}).items():
        ret['cifs-client']['mounts'][mount] = {
            'group': data.get('group', 'root'),
            'owner': data.get('owner', 'root'),
            'mode': data.get('mode', '0755'),
            'mount_options': {
                'dir_mode': data.get('mount_options', {}).get('dir_mode', '0755'),
                'file_mode': data.get('mount_options', {}).get('file_mode', '0644'),
                'credentials': '/etc/cifs-credentials/{}'.format(mount),
                'uid': data.get('owner', 'root'),
                'gid': data.get('group','root'),
            },
            'mountpoint': data.get('mountpoint', '/var/opt/{}'.format(mount)),
            'type': data.get('type', 'cifs'),
            'unitname': data['mountpoint'][1:].replace('-', '\\x2d').replace('/', '-'),
            'mount': mount,
            'depends_on': {},
        }
        if data.get('credentials', None):
            ret['cifs-client']['mounts'][mount]['mount_options']['credentials'] = '/etc/cifs-credentials/{}'.format(mount),

    return ret
