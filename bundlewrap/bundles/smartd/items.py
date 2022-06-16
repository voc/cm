files = {
    '/etc/smartd.conf': {
        'content_type': 'mako',
        'triggers': {
            'svc_systemd:smartd:reload',
        },
    },
    '/usr/local/share/icinga/plugins/check_smart': {
        'mode': '0755',
    },
}

svc_systemd = {
    'smartd': {
        'enabled': None, # FIXME this is symlinked to smartmontools.service on bullseye
    },
}
