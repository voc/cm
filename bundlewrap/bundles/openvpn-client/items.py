import bwkeepass as keepass

svc_systemd = {
    'openvpn@voc': {
        'enabled': True,
        'needs': {
            'pkg_apt:openvpn',
            'file:/etc/openvpn/voc.conf',
            'file:/etc/openvpn/ca.crt',
            'file:/etc/openvpn/ta.key',
            f"file:/etc/openvpn/{node.name}.crt",
            f"file:/etc/openvpn/{node.name}.key",
        },
    },
}

files = {
    '/etc/openvpn/voc.conf': {
        'content_type': 'mako',
        'triggers': {
            'svc_systemd:openvpn@voc:restart',
        },
    },
    '/etc/openvpn/ca.crt': {
        'content': keepass.notes(['ansible', 'vpn', 'ca.crt']),
        'triggers': {
            'svc_systemd:openvpn@voc:restart',
        },
    },
    '/etc/openvpn/ta.key': {
        'content': keepass.notes(['ansible', 'vpn', 'ta.key']),
        'triggers': {
            'svc_systemd:openvpn@voc:restart',
        },
    },
    f"/etc/openvpn/{node.name}.crt": {
        'content': keepass.notes(['ansible', 'vpn', f"{node.name}.crt"]),
        'triggers': {
            'svc_systemd:openvpn@voc:restart',
        },
    },
    f"/etc/openvpn/{node.name}.key": {
        'content': keepass.notes(['ansible', 'vpn', f"{node.name}.key"]),
        'triggers': {
            'svc_systemd:openvpn@voc:restart',
        },
    },
}
