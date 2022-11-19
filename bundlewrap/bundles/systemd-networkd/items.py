from bundlewrap.exceptions import BundleError

assert node.has_bundle('systemd')

files = {
    '/etc/network/interfaces': {
        'delete': True,
    },
    '/etc/resolv.conf': {
        'after': {
            'pkg_apt:',
        },
    },
}

svc_systemd = {
    'systemd-networkd': {
        'after': {
            'pkg_apt:',
        },
    },
    'systemd-resolved': {
        'running': False,
        'enabled': False,
        'after': {
            'file:/etc/resolv.conf',
            'pkg_apt:',
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
