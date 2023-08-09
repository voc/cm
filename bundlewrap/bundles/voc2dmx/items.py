directories['/opt/voc2dmx/src'] = {}
git_deploy['/opt/voc2dmx/src'] = {
    'repo': 'https://git.franzi.business/kunsi/viri-leds-dmx-sacn.git',
    'rev': 'main',
    'triggers': {
        'action:voc2dmx_install_deps',
        'svc_systemd:voc2dmx:restart',
    },
}

actions['voc2dmx_create_virtualenv'] = {
    'command': 'python3 -m virtualenv /opt/voc2dmx/venv',
    'unless': 'test -d /opt/voc2dmx/venv',
    'needs': {
        'directory:/opt/voc2dmx/src',
    },
}

actions['voc2dmx_install_deps'] = {
    'command': 'cd /opt/voc2dmx/src && /opt/voc2dmx/venv/bin/pip install -r requirements.txt',
    'triggered': True,
    'needs': {
        'action:voc2dmx_create_virtualenv',
    },
}

files['/opt/voc2dmx/config.toml'] = {
    'content_type': 'mako',
    'context': {
        'config': node.metadata.get('voc2dmx'),
    },
}

files['/usr/local/lib/systemd/system/voc2dmx.service'] = {
    'triggers': {
        'action:systemd-reload',
        'svc_systemd:voc2dmx:restart',
    },
}

svc_systemd['voc2dmx'] = {
    'needs': {
        'action:voc2dmx_install_deps',
        'file:/opt/voc2dmx/config.toml',
        'file:/usr/local/lib/systemd/system/voc2dmx.service',
        'git_deploy:/opt/voc2dmx/src',
    },
}
