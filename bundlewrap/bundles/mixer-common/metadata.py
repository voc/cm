import bwkeepass as keepass

defaults = {
    'apt': {
        'packages': {
            'fonts-roboto': {},
            'i3-wm': {},
            'i3status': {},
            'irssi': {},
            'kitty': {},
            'slim': {},
            'x11-utils': {},
            'x11-xserver-utils': {},
            'x11vnc': {},
            'xdotool': {},
            'xserver-xorg': {},
        },
    },
    'users': {
        'mixer': {
            'password': keepass.password(['ansible', 'logins', 'mixer']),
        },
    },
}
