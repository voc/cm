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

files['/home/mixer/.irssi/config'] = {
    'content_type': 'mako',
    'source' : "irssi/config",
    'owner': 'mixer',
    'group': 'mixer',
}

files['/home/mixer/.config/i3/config'] = {
    'source' : "i3/config",
    'owner': 'mixer',
    'group': 'mixer',
}

files['/home/mixer/.config/i3/layout.json'] = {
    'source' : "i3/layout.json",
    'owner': 'mixer',
    'group': 'mixer',
}

files['/usr/local/bin/voctogui-i3-layout.sh'] = {
    'source' : 'i3/voctogui-i3-layout.sh',
    'mode': 755,
}

files['/home/mixer/.config/kitty/kitty.conf'] = {
    'source' : "kitty/kitty.conf",
    'owner': 'mixer',
    'group': 'mixer',
}

for script in [ 'knast.pl', 'selectvocmixer.pl' ]:
    files[f'/home/mixer/.irssi/scripts/{script}'] = {
        'source' : f'irssi/{script}',
        'owner': 'mixer',
        'group': 'mixer',
    }

    symlinks[f'/home/mixer/.irssi/scripts/autorun/{script}'] = {
        'target' : f'/home/mixer/.irssi/scripts/{script}',
        'owner': 'mixer',
        'group': 'mixer',
    }
