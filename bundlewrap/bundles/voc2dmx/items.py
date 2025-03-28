directories['/opt/voc2dmx/src'] = {}

actions['voc2dmx_create_virtualenv'] = {
    'command': '/usr/bin/python3 -m virtualenv -p python3 /opt/voc2dmx/venv',
    'unless': 'test -d /opt/voc2dmx/venv',
    'needs': {
        'directory:/opt/voc2dmx/src',
        'pkg_apt:python3-virtualenv',
    },
}

git_deploy['/opt/voc2dmx/src'] = {
    'repo': 'https://git.franzi.business/kunsi/viri-leds-dmx-sacn.git',
    'rev': 'main',
    'triggers': {
        'action:voc2dmx_install',
        'svc_systemd:voc2dmx:restart',
    },
}

actions['voc2dmx_install'] = {
    'triggered': True,
    'command': ' && '.join([
        'cd /opt/voc2dmx/src',
        '/opt/voc2dmx/venv/bin/pip install --upgrade pip',
        '/opt/voc2dmx/venv/bin/pip install --upgrade -r requirements.txt',
    ]),
    'needs': {
        'action:voc2dmx_create_virtualenv',
    }
}

files['/opt/voc2dmx/config.toml'] = {
    'content': repo.libs.faults.dict_as_toml(node.metadata.get('voc2dmx')),
    'triggers': {
        'svc_systemd:voc2dmx:restart',
    },
}

files['/usr/local/lib/systemd/system/voc2dmx.service'] = {
    'triggers': {
        'action:systemd-reload',
        'svc_systemd:voc2dmx:restart',
    },
}

users['voc2dmx'] = {
    'home': '/opt/voc2dmx',
    'uid': 1998,
}

svc_systemd['voc2dmx'] = {
    'needs': {
        'action:voc2dmx_install',
        'file:/opt/voc2dmx/config.toml',
        'file:/usr/local/lib/systemd/system/voc2dmx.service',
        'user:voc2dmx',
    },
}
