if node.has_bundle('pacman'):
    package = 'pkg_pacman:nftables'
else:
    package = 'pkg_apt:nftables'

directories = {
    # used by other bundles
    '/etc/nftables-rules.d': {
        'purge': True,
        'triggers': {
            'svc_systemd:nftables:reload',
        },
    },
}

files = {
    '/etc/nftables.conf': {
        'content_type': 'mako',
        'context': {
            'forward': node.metadata.get('nftables/forward', {}),
            'input': node.metadata.get('nftables/input', {}),
            'postrouting': node.metadata.get('nftables/postrouting', {}),
            'prerouting': node.metadata.get('nftables/prerouting', {}),
        },
        'triggers': {
            'svc_systemd:nftables:reload',
        },
    },
    '/etc/systemd/system/nftables.service.d/bundlewrap.conf': {
        'source': 'override.conf',
        'content_type': 'mako',
        'triggers': {
            'action:systemd-reload',
            'svc_systemd:nftables:reload',
        },
    },
}

svc_systemd = {
    'nftables': {
        'needs': {
            'file:/etc/nftables.conf',
            package,
        },
    },
}
