files['/etc/default/rsync'] = {
    'source': 'etc-default',
    'triggers': {
        'svc_systemd:rsync:restart',
    },
}

files['/etc/rsyncd.conf'] = {
    'content_type': 'mako',
    'context': {
        'shares': node.metadata.get('rsync/shares', {}),
    },
    'triggers': {
        'svc_systemd:rsync:restart',
    },
}

svc_systemd['rsync'] = {
    'needs': {
        'file:/etc/default/rsync',
        'pkg_apt:rsync',
    },
}
