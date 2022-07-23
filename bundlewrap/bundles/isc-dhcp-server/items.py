files = {
    '/etc/dhcp/dhcpd.conf': {
        'content_type': 'mako',
        'context': {
            'dhcp_config': node.metadata.get('isc-dhcp-server'),
        },
        'needs': {
            'pkg_apt:isc-dhcp-server'
        },
        'triggers': {
            'action:dhcpd_check_config',
        },
    },
    '/etc/default/isc-dhcp-server': {
        'content_type': 'mako',
        'needs': {
            'pkg_apt:isc-dhcp-server'
        },
        'triggers': {
            'action:dhcpd_check_config',
        },
    },
    '/usr/local/etc/oui.txt': {
        'content_type': 'download',
        'source': 'http://standards-oui.ieee.org/oui.txt',
    },
}
actions = {
    'dhcpd_check_config': {
        'command': 'dhcpd -t',
        'triggered': True,
        'triggers': {
            'svc_systemd:isc-dhcp-server:restart',
        },
    },
}

svc_systemd = {
    'isc-dhcp-server': {
        'needs': {
            'pkg_apt:isc-dhcp-server',
            'file:/etc/dhcp/dhcpd.conf',
            'file:/etc/default/isc-dhcp-server',
        },
    },
}
