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
    'bash_aliases': {
        'fix_layout': 'sudo -Hu mixer DISPLAY=:0 /usr/local/bin/i3-layout.sh',
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


@metadata_reactor.provides(
    'mixer-common/i3_layout',
)
def i3_layout(metadata):
    if not node.has_bundle('voctogui'):
        raise DoNotRunAgain

    options = ['voctogui']

    if node.has_bundle('pygtk-atem-switcher'):
        options.append('atem')

    if metadata.get('mixer-common/enable-irssi'):
        options.append('irssi')

    return {
        'mixer-common': {
            'i3_layout': '_'.join(options),
        },
    }

