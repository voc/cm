directories = {
    '/etc/cifs-credentials': {
        'mode': '0400',
        'purge': True,
    },
}

for mount, data in node.metadata.get('cifs-client', {}).get('mounts', {}).items():
    unitname = data['mountpoint'][1:].replace('-', '\\x2d').replace('/', '-')

    if data.get('create_dir', False):
        directories[data['mountpoint']] = {}

    mount_options = set()
    for opt, value in data.get('mount_options', {}).items():
        if value is not None:
            mount_options.add(f'{opt}={value}')
        else:
            mount_options.add(opt)

    files[f'/usr/local/lib/systemd/system/{unitname}.mount'] = {
        'mode': '0644',
        'source': 'cifs.mount',
        'content_type': 'mako',
        'context': {
            'mount': mount,
            'opts': ','.join(sorted(mount_options)),
            **data,
        },
        'triggers': [
            'action:systemd-reload',
        ],
    }

    svc_systemd[f'{unitname}.mount'] = {
        'needs': [
            'file:/usr/local/lib/systemd/system/{}.mount'.format(unitname),
            'directory:{}'.format(data['mountpoint']),
        ],
    }

    if data.get('credentials'):
        files[f'/etc/cifs-credentials/{mount}'] = {
            'mode': '0400',
            'source': 'cifs.credentials',
            'content_type': 'mako',
            'context': data,
            'triggers': {
                'action:systemd-reload',
                f'svc_systemd:{unitname}.mount:restart',
            },
        }
        svc_systemd[f'{unitname}.mount']['needs'].add(f'file:/etc/cifs-credentials/{mount}')

