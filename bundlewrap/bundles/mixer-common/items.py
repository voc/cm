files['/etc/slim.conf'] = {
    'triggers': {
        'svc_systemd:display-manager:restart',
    },
}

svc_systemd['display-manager'] = {
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
    'triggers': {
        'svc_systemd:display-manager:restart',
    },
}

files['/home/mixer/.irssi/config'] = {
    'content_type': 'mako',
    'source' : 'irssi/config',
    'owner': 'mixer',
    'group': 'mixer',
    'triggers': {
        'svc_systemd:display-manager:restart',
    },
}

files['/home/mixer/.config/i3/config'] = {
    'source' : 'i3/config',
    'content_type': 'mako',
    'owner': 'mixer',
    'group': 'mixer',
    'triggers': {
        'svc_systemd:display-manager:restart',
    },
}

files['/home/mixer/.config/i3status/config'] = {
    'delete': True,
}

files['/home/mixer/.config/i3pystatus/config.py'] = {
    'source' : 'i3pystatus_config.py',
    'owner': 'mixer',
    'group': 'mixer',
    'triggers': {
        'svc_systemd:display-manager:restart',
    },
}

files['/home/mixer/.config/i3/layout.json'] = {
    'source' : 'i3_layout/{}.json'.format(node.metadata.get('mixer-common/i3_layout')),
    'owner': 'mixer',
    'group': 'mixer',
    'triggers': {
        'action:mixer-common_apply_i3_layout',
    },
}

files['/usr/local/bin/i3-layout.sh'] = {
    'source' : 'i3/i3-layout.sh',
    'mode': 755,
    'triggers': {
        'action:mixer-common_apply_i3_layout',
    },
}

actions['mixer-common_apply_i3_layout'] = {
    'command': 'sudo -Hu mixer DISPLAY=:0 /usr/local/bin/i3-layout.sh',
    'triggered': True,
    'after': {
        'action:',
        'svc_systemd:',
    },
}

files['/usr/local/sbin/brightness'] = {
    'mode': 755,
}

files['/home/mixer/.config/kitty/kitty.conf'] = {
    'source' : 'kitty/kitty.conf',
    'owner': 'mixer',
    'group': 'mixer',
    'triggers': {
        'svc_systemd:display-manager:restart',
    },
}

for script in [ 'knast.pl', 'selectvocmixer.pl' ]:
    files[f'/home/mixer/.irssi/scripts/{script}'] = {
        'source' : f'irssi/{script}',
        'owner': 'mixer',
        'group': 'mixer',
        'triggers': {
            'svc_systemd:display-manager:restart',
        },
    }

    symlinks[f'/home/mixer/.irssi/scripts/autorun/{script}'] = {
        'target' : f'/home/mixer/.irssi/scripts/{script}',
        'owner': 'mixer',
        'group': 'mixer',
        'triggers': {
            'svc_systemd:display-manager:restart',
        },
    }

directories['/opt/i3pystatus/src'] = {}

actions['i3pystatus_create_virtualenv'] = {
    'command': '/usr/bin/python3 -m virtualenv -p python3 /opt/i3pystatus/venv/',
    'unless': 'test -d /opt/i3pystatus/venv/',
    'needs': {
        'directory:/opt/i3pystatus/src',
        'pkg_apt:python3-virtualenv',
    },
}

actions['i3pystatus_install'] = {
    'command': ' && '.join([
        'cd /opt/i3pystatus/src',
        '/opt/i3pystatus/venv/bin/pip install --upgrade pip colour netifaces',
        '/opt/i3pystatus/venv/bin/pip install --upgrade -e .',
    ]),
    'needs': {
        'action:i3pystatus_create_virtualenv',
    },
    'after': {
        'pkg_apt:',
    },
    'triggered': True,
}

git_deploy['/opt/i3pystatus/src'] = {
    'repo': 'https://github.com/enkore/i3pystatus.git',
    'rev': 'current',
    'triggers': {
        'action:i3pystatus_install',
        'svc_systemd:display-manager:restart',
    },
}
