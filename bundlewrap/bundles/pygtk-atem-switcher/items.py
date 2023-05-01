directories['/opt/pygtk-atem-switcher/src'] = {}

git_deploy['/opt/pygtk-atem-switcher/src'] = {
    'repo': 'https://github.com/Kunsi/pygtk-atem-switcher.git',
    'rev': 'development', # TODO use releases
    'triggers': {
        'action:pygtk-atem-switcher_install_deps',
        'svc_systemd:pygtk-atem-switcher:restart',
    }
}

actions['pygtk-atem-switcher_create_virtualenv'] = {
    'command': '/usr/bin/python3 -m virtualenv -p python3 /opt/pygtk-atem-switcher/venv',
    'unless': 'test -d /opt/pygtk-atem-switcher/venv',
    'needs': {
        # actually /opt/pygtk-atem-switcher, but we don't manage that
        'directory:/opt/pygtk-atem-switcher/src',
    },
}

actions['pygtk-atem-switcher_install_deps'] = {
    'triggered': True,
    'command': '/opt/pygtk-atem-switcher/venv/bin/pip install --upgrade pip -r /opt/pygtk-atem-switcher/src/requirements.txt',
    'needs': {
        'action:pygtk-atem-switcher_create_virtualenv',
    },
}

files['/opt/pygtk-atem-switcher/config.toml'] = {
    'content_type': 'mako',
    'context': {
        'config': node.metadata.get('pygtk-atem-switcher'),
    },
    'triggers': {
        'svc_systemd:pygtk-atem-switcher:restart',
    }
}

files['/usr/local/lib/systemd/system/pygtk-atem-switcher.service'] = {
    'content_type': 'mako',
    'context': {
        'high_dpi': node.metadata.get('voctogui/high_dpi'),
    },
    'triggers': {
        'action:systemd-reload',
        'svc_systemd:pygtk-atem-switcher:restart',
    }
}

svc_systemd['pygtk-atem-switcher'] = {
    'needs': {
        'file:/usr/local/lib/systemd/system/pygtk-atem-switcher.service',
        'git_deploy:/opt/pygtk-atem-switcher/src',
    },
    'after': {
        # do not create a hard dependency on the installation of stuff.
        # if this fails, we maybe have some old stuff lying around, that
        # should be fine.
        'action:pygtk-atem-switcher_install_deps',
    },
}
