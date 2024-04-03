# TODO remove this once releasing is managed using bundlewrap.
# Use the regular `encoder-common` bundles after that

event = node.metadata.get('event/slug')

directories[f'/video/encoded/{event}'] = {
    'group': 'voc',
    'mode': '0775',
    'owner': 'upload'
}

actions = {
    'systemd-reload': {
        'command': 'systemctl daemon-reload',
        'triggered': True,
        'before': {
            'svc_systemd:',
        },
    },
}
