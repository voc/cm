svc_systemd = {
    'nmbd': {
        'needs': {
            'pkg_apt:samba',
        },
    },
    'smbd': {
        'needs': {
            'pkg_apt:samba',
        },
    },
}

files = {
    '/etc/samba/smb.conf': {
        'content_type': 'mako',
        'triggers': {
            'svc_systemd:nmbd:restart',
            'svc_systemd:smbd:restart',
        },
    },
    '/etc/systemd/system/nmbd.service.d/bundlewrap.conf': {
        'source': 'override.conf',
        'triggers': {
            'action:systemd-reload',
            'svc_systemd:nmbd:restart',
        },
    },
    '/etc/systemd/system/smbd.service.d/bundlewrap.conf': {
        'source': 'override.conf',
        'triggers': {
            'action:systemd-reload',
            'svc_systemd:smbd:restart',
        },
    },
}
