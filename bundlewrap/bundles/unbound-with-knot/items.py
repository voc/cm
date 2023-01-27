files['/etc/knot/update.sh'] = {
    'source': 'knot-update.sh',
    'mode': '0700',
    'content_type': 'mako',

    'needed_by': {
        'svc_systemd:knot_update.timer',
    },
}

actions['knot_init_config'] = {
    'command': 'systemctl start knot_update.service',
    'unless': 'test -f /etc/knot/knot.conf',
    'after': {
        'pkg_apt:',
        'svc_systemd:knot_update.timer',
    },
}

svc_systemd['knot'] = {
    'needs': {
        'action:knot_init_config',
        'pkg_apt:knot',
    },
}

files['/etc/unbound/unbound.conf'] = {
    'content_type': 'mako',
    'context': node.metadata.get('unbound-with-knot'),
    'triggers': {
        'svc_systemd:unbound:restart',
    },
}

svc_systemd['unbound'] = {
    'needs': {
        'file:/etc/unbound/unbound.conf',
        'pkg_apt:unbound',
        'pkg_apt:unbound-anchor',
    },
}
