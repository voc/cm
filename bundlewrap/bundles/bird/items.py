files['/etc/bird/bird.conf'] = {
    'content_type': 'mako',
    'triggers': {
        'svc_systemd:bird:reload',
    },
}

svc_systemd['bird'] = {
    'needs': {
        f'file:/etc/bird/bird.conf',
        'pkg_apt:bird',
    },
}
