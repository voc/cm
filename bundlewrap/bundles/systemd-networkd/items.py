from bundlewrap.exceptions import BundleError

assert node.has_bundle('systemd')

files = {
    '/etc/network/interfaces': {
        'delete': True,
    },
    '/etc/resolv.conf': {
        'content_type': 'mako',
        'after': {
            'pkg_apt:',
        },
    },
    '/usr/local/lib/systemd/system/systemd-networkd-wait-online.service': {
        'triggers': {
            'action:systemd-reload',
            'svc_systemd:systemd-networkd-wait-online:restart',
        },
    },
}

svc_systemd = {
    'systemd-networkd': {
        'after': {
            'pkg_apt:',
        },
        'tags': {
            'causes-downtime',
        },
    },
    'systemd-networkd-wait-online': {
        'needs': {
            'file:/usr/local/lib/systemd/system/systemd-networkd-wait-online.service',
            'svc_systemd:systemd-networkd',
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
    if node.metadata.get(f'systemd-networkd/bonds/{interface}', {}):
        continue

    files[f'/etc/systemd/network/{interface}.network'] = {
        'source': 'template-iface.network',
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

    if '.' in interface:
        files[f'/etc/systemd/network/{interface}.netdev'] = {
            'source': 'template-iface-vlan.netdev',
            'content_type': 'mako',
            'context': {
                'interface': interface,
                'vlan': interface.split('.', 1)[1],
            },
            'needed_by': {
                'svc_systemd:systemd-networkd',
            },
            'triggers': {
                'svc_systemd:systemd-networkd:restart',
            },
        }

for bond, config in node.metadata.get('systemd-networkd/bonds', {}).items():
    files[f'/etc/systemd/network/{bond}.netdev'] = {
        'source': 'template-bond.netdev',
        'content_type': 'mako',
        'context': {
            'bond': bond,
            'mode': config.get('mode', '802.3ad'),
            'prio': config.get('priority', '32768'),
        },
        'needed_by': {
            'svc_systemd:systemd-networkd',
        },
        'triggers': {
            'svc_systemd:systemd-networkd:restart',
        },
    }

    files[f'/etc/systemd/network/{bond}.network'] = {
        'source': 'template-bond.network',
        'content_type': 'mako',
        'context': {
            'bond': bond,
            'match': config['match'],
            'vlans': node.metadata.get(f'interfaces/{bond}/vlans', set()),
        },
        'needed_by': {
            'svc_systemd:systemd-networkd',
        },
        'triggers': {
            'svc_systemd:systemd-networkd:restart',
        },
    }

for brname, config in node.metadata.get('systemd-networkd/bridges', {}).items():
    filename = '{}-match-{}'.format(
        brname,
        '-'.join(sorted(config['match'])),
    ).replace('*', '_')

    files[f'/etc/systemd/network/{brname}.netdev'] = {
        'source': 'template-bridge.netdev',
        'content_type': 'mako',
        'context': {
            'bridge': brname,
        },
        'needed_by': {
            'svc_systemd:systemd-networkd',
        },
        'triggers': {
            'svc_systemd:systemd-networkd:restart',
        },
    }

    files[f'/etc/systemd/network/{filename}.network'] = {
        'source': 'template-bridge.network',
        'content_type': 'mako',
        'context': {
            'bridge': brname,
            'match': config['match'],
        },
        'needed_by': {
            'svc_systemd:systemd-networkd',
        },
        'triggers': {
            'svc_systemd:systemd-networkd:restart',
        },
    }

    if config.get('vlans', set()):
        files[f'/etc/systemd/network/{brname}.network'] = {
            'source': 'template-bridge-vlan.network',
            'content_type': 'mako',
            'context': {
                'bridge': brname,
                'vlans': config.get('vlans', set()),
            },
            'needed_by': {
                'svc_systemd:systemd-networkd',
            },
            'triggers': {
                'svc_systemd:systemd-networkd:restart',
            },
        }
