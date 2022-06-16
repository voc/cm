directories = {
    '/etc/cifs-credentials': {
        'mode': '0400',
        'purge': True,
    },
}
files = {}
svc_systemd = {}


for mount, data in node.metadata.get('cifs-client', {}).get('mounts', {}).items():
    directories[data['mountpoint']] = {
        'needs': data.get('needs', set()),
    }
    for parameter in ['mode', 'owner', 'group']:
        if parameter in data:
            directories[data['mountpoint']][parameter] = data[parameter]
    if node.has_bundle('zfs'):
        directories[data['mountpoint']]['needs'].add('zfs_pool:')
        directories[data['mountpoint']]['needs'].add('zfs_dataset:')
    files['/etc/systemd/system/{}.mount'.format(data['unitname'])] = {
        'mode': "0644",
        'source': "cifs.mount",
        'content_type': 'mako',
        'context': data,
        'triggers': [
            "action:systemd-daemon-reload",
        ],
    }
    svc_systemd['{}.mount'.format(data['unitname'])] = {
        'needs': [
            'file:/etc/systemd/system/{}.mount'.format(data['unitname']),
            'file:/etc/cifs-credentials/{}'.format(mount),
            'directory:{}'.format(data['mountpoint']),
        ],
    }
    if data.get('credentials', None):
        files['/etc/cifs-credentials/{}'.format(mount)] = {
            'mode': "0400",
            'source': "cifs.credentials",
            'content_type': 'mako',
            'context': data,
            'triggers': [
                "action:systemd-daemon-reload",
                'svc_systemd:{}.mount:restart'.format(data['unitname']),
            ],
        }
        svc_systemd['{}.mount'.format(data['unitname'])]['needs'].append(
                'file:/etc/cifs-credentials/{}'.format(mount))

