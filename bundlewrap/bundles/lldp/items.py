directories = {
    '/etc/lldpd.d': {
        'purge': True,
        'triggers': {
            'svc_systemd:lldpd:restart',
        },
    },
}

files = {
    '/etc/lldpd.conf': {
        'delete': True,
    },
    '/etc/lldpd.d/bundlewrap.conf': {
        'content_type': 'mako',
        'triggers': {
            'svc_systemd:lldpd:restart',
        },
    },
}

svc_systemd = {
    'lldpd': {
        'needs': {
            'file:/etc/lldpd.d/bundlewrap.conf',
        },
    },
}
