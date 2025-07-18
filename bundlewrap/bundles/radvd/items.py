SHOULD_BE_RUNNING = node.metadata.get('radvd/is_enabled')

files['/etc/radvd.conf'] = {
    'content_type': 'mako',
    'context': {
        'interfaces': node.metadata.get('radvd/interfaces'),
    },
    'triggers': {
        'svc_systemd:radvd:restart',
    } if SHOULD_BE_RUNNING else set(),
}

svc_systemd = {
    'radvd': {
        'running': SHOULD_BE_RUNNING,
        'enabled': SHOULD_BE_RUNNING,
        'needs': {
            'pkg_apt:radvd',
            'file:/etc/radvd.conf',
        },
    },
}
