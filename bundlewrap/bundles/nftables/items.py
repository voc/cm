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
        'needs': {
            'directory:/etc/nftables-rules.d',
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

for ruleset, rules in node.metadata.get('nftables/rules', {}).items():
    files[f'/etc/nftables-rules.d/{ruleset}'] = {
        'source': 'rules-template',
        'content_type': 'mako',
        'context': {
            'rules': rules,
        },
        'needed_by': {
            'svc_systemd:nftables',
        },
        'triggers': {
            'svc_systemd:nftables:reload',
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
