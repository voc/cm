import bwkeepass as keepass

defaults = {
    'apt': {
        'packages': {
            'fonts-roboto': {},
            'irssi': {},
            'slim': {},
            'i3-wm': {},
            'x11vnc': {},
            'x11-xserver-utils': {},
            'xserver-xorg': {},
            'kitty': {},
        },
    },
    'users': {
        'mixer': {
            'password': keepass.password(['ansible', 'logins', 'mixer']),
        },
    },
}
