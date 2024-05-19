actions = {
    'sampleplayer_create_virtualenv': {
        'command': '/usr/bin/python3 -m virtualenv -p python3 /opt/sampleplayer/venv/',
        'unless': 'test -d /opt/sampleplayer/venv/',
        'needs': {
            # actually /opt/sampleplayer, but we don't create that
            'directory:/opt/sampleplayer/src',
        },
    },
    'sampleplayer_install_requirements': {
        'command': ' && '.join([
            'cd /opt/sampleplayer/src',
            '/opt/sampleplayer/venv/bin/pip install --upgrade pip gunicorn -r requirements.txt',
        ]),
        'needs': {
            'action:sampleplayer_create_virtualenv',
            'pkg_apt:',
        },
        'triggered': True,
    },
}

directories['/opt/sampleplayer/src'] = {}

git_deploy['/opt/sampleplayer/src'] = {
    'repo': 'https://git.franzi.business/sophie/sampleplayer.git',
    'rev': 'main',
    'triggers': {
        'action:sampleplayer_install_requirements',
        'svc_systemd:sampleplayer:restart',
    },
}

files['/usr/local/lib/systemd/system/sampleplayer.service'] = {
    'triggers': {
        'action:systemd-reload',
        'svc_systemd:sampleplayer:restart',
    },
}

svc_systemd['sampleplayer'] = {
    'needs': {
        'git_deploy:/opt/sampleplayer/src',
        'action:sampleplayer_install_requirements',
        'pkg_apt:',
    },
}

users = {
    'sampleplayer': {
        'home': '/opt/sampleplayer',
    },
}
