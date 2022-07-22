assert node.has_bundle('voctomix2')

files['/etc/systemd/system/voctolight.service'] = {
    'delete': True,
    'triggers': {
        'action:systemd-reload',
    },
}

files['/usr/local/lib/systemd/system/voctolight.service'] = {
    'triggers': {
        'action:systemd-reload',
        'svc_systemd:voctolight:restart',
    },
}

files['/etc/voctolight.ini'] = {
    'content_type': 'mako',
    'context': {
        'light': node.metadata.get('voctolight'),
    },
}

svc_systemd['voctolight'] = {
    'needs': {
        'file:/etc/voctolight.ini',
        'file:/usr/local/lib/systemd/system/voctolight.service',
        'git_deploy:/opt/voctomix2/release',
        'pkg_apt:python-rpi.gpio',
    },
}
