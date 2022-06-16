from bundlewrap.exceptions import BundleError

assert node.has_bundle('systemd')

files = {
    '/etc/network/interfaces': {
        'delete': True,
    },
    '/etc/systemd/resolved.conf': {
        'triggers': {
            'svc_systemd:systemd-resolved:restart',
        },
    },
}

svc_systemd = {
    'systemd-networkd': {},
    'systemd-resolved': {},
}

symlinks = {
    '/etc/resolv.conf': {
        'target': '/var/systemd/resolv.conf',
        'needs': {
            'svc_systemd:systemd-resolved',
        },
    },
}

directories = {
    '/etc/systemd/network': {
        'purge': True,
        'needed_by': {
            'svc_systemd:systemd-networkd',
        },
        'triggers': {
            'svc_systemd:systemd-networkd:restart',
        },
    },
}


for interface, config in node.metadata.get('interfaces').items():
    if config.get('dhcp', False):
        template = 'template-iface-dhcp.network'
    else:
        template = 'template-iface-nodhcp.network'

    files[f'/etc/systemd/network/{interface}.network'] = {
        'source': template,
        'content_type': 'mako',
        'context': {
            'interface': interface,
            'config': config,
        },
        'needed_by': {
            'svc_systemd:systemd-networkd',
        },
        'triggers': {
            'svc_systemd:systemd-networkd:restart',
        },
    }
