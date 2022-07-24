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
    'context': {
        'room_name': node.metadata.get('event/room_name'),
    },
    'triggers': {
        'svc_systemd:display-manager:restart',
    },
}

files['/home/mixer/.config/i3/config'] = {
    'source' : 'i3/config',
    'owner': 'mixer',
    'group': 'mixer',
    'triggers': {
        'svc_systemd:display-manager:restart',
    },
}

files['/home/mixer/.config/i3status/config'] = {
    'source' : 'i3status/config',
    'owner': 'mixer',
    'group': 'mixer',
    'triggers': {
        'svc_systemd:display-manager:restart',
    },
}

files['/home/mixer/.config/i3/layout.json'] = {
    'source' : 'i3/layout.json',
    'owner': 'mixer',
    'group': 'mixer',
    'triggers': {
        'svc_systemd:display-manager:restart',
    },
}

files['/usr/local/bin/voctogui-i3-layout.sh'] = {
    'source' : 'i3/voctogui-i3-layout.sh',
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
