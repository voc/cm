from bundlewrap.exceptions import BundleError

assert node.has_bundle('systemd')

files = {
    '/etc/network/interfaces': {
        'delete': True,
    },
    '/etc/systemd/resolved.conf': {
        'content_type': 'mako',
        'context': {
            'nameservers': node.metadata.get('nameservers', ['5.1.66.255', '185.150.99.255', '194.150.168.168', '1.1.1.1']),
            'domains': node.metadata.get('dns_search_domains', ['lan.c3voc.de']),
        },
        'triggers': {
            'svc_systemd:systemd-resolved:restart',
        },
    },
}

svc_systemd = {
    'systemd-networkd': {
        'after': {
            'pkg_apt:',
        },
    },

if node.os_version[0] > 9:
    svc_systemd['systemd-resolved'] = {
        'after': {
            'pkg_apt:',
        },
    }

    symlinks = {
        '/etc/resolv.conf': {
            'target': '/lib/systemd/resolv.conf',
            'needs': {
                'svc_systemd:systemd-resolved',
            },
        },
    }
else:
    files['/etc/resolv.conf'] = {
        'after': {
            'pkg_apt:',
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
