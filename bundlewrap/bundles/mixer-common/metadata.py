import bwkeepass as keepass

defaults = {
    'apt': {
        'packages': {
            'dwm-voc': {},
            'fonts-roboto': {},
            'irrsi': {},
            'runit': {},
            'slim': {},
            'x11vnc': {},
            'x11-xserver-utils': {},
            'xserver-xorg': {},
            'xterm': {},
        },
    },
    'users': {
        'mixer': {
            'password': keepass.password(['ansible', 'logins', 'mixer']),
        },
    },
}
