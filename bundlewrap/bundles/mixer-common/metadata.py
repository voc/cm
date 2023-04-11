import bwkeepass as keepass

defaults = {
    'apt': {
        'packages': {
            'fonts-roboto': {},
            'i3-wm': {},
            'i3status': {},
            'irssi': {},
            'kitty': {},
            'netcat': {},
            'slim': {},
            'x11-utils': {},
            'x11-xserver-utils': {},
            'x11vnc': {},
            'xdotool': {},
            'xserver-xorg': {},
        },
    },
    'mixer-common': {
        'enable-irssi': True,
    },
    'users': {
        'mixer': {
            'groups': {
                'video',
            },
            'sudo_commands': {
                '/usr/local/sbin/brightness',
            },
        },
    },
}
