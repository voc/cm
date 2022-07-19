files['/etc/slim.conf'] = {
    'triggers': {
        'svc_systemd:slim:restart',
    },
    'tags': {
        'causes-downtime',
    },
}

svc_systemd['slim'] = {
    'needs': {
        'pkg_apt:slim',
        'file:/etc/slim.conf',
    },
    'tags': {
        'causes-downtime',
    },
}

files['/home/mixer/.xsession'] = {
    'source': 'xsession',
    'owner': 'mixer',
    'group': 'mixer',
}
