
directories['/opt/ffmpeg2mqtt/src'] = {}

actions['ffmpeg2mqtt_create_virtualenv'] = {
    'command': '/usr/bin/python3 -m virtualenv -p python3 /opt/ffmpeg2mqtt/venv',
    'unless': 'test -d /opt/ffmpeg2mqtt/venv',
    'needs': {
        'directory:/opt/ffmpeg2mqtt/src',
        'pkg_apt:python3-virtualenv',
    },
}

git_deploy['/opt/ffmpeg2mqtt/src'] = {
    'repo': 'https://github.com/scientress/ffmpeg2mqtt.git',
    'rev': 'main',
    'triggers': {
        'action:ffmpeg2mqtt_install',
        'svc_systemd:ffmpeg2mqtt:restart',
    },
}

actions['ffmpeg2mqtt_install'] = {
    'triggered': True,
    'needs': {
        'action:ffmpeg2mqtt_create_virtualenv',
    },
    'command': ' && '.join([
        'cd /opt/ffmpeg2mqtt/src',
        '/opt/ffmpeg2mqtt/venv/bin/pip install --upgrade pip',
        '/opt/ffmpeg2mqtt/venv/bin/pip install .',
    ]),
}

files['/usr/local/lib/systemd/system/ffmpeg2mqtt.service'] = {
    'content_type': 'mako',
    'triggers': {
        'action:systemd-reload',
        'svc_systemd:ffmpeg2mqtt:restart',
    },
}

users['ffmpeg2mqtt'] = {
    'home': '/opt/ffmpeg2mqtt',
    'uid': 1997,
}

svc_systemd['ffmpeg2mqtt'] = {
    'needs': {
        'action:ffmpeg2mqtt_install',
        'file:/usr/local/lib/systemd/system/ffmpeg2mqtt.service',
        'user:ffmpeg2mqtt',
    },
}
