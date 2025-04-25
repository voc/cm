defaults = {
    'apt': {
        'packages': {
            'fonts-roboto': {},
            'i3-wm': {},
            'i3status': {},
            'irssi': {},
            'kitty': {},
            'netcat-openbsd': {},
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

if node.os_version >= (11,):
    defaults['apt']['packages']['terminus'] = {}

@metadata_reactor.provides(
    'mixer-common/i3_layout',
)
def i3_layout(metadata):
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


@metadata_reactor.provides(
    'kitty/fontsize',
)
def kittyfontsize(metadata):
    #high_dpi = false makes font smaller
    if not metadata.get('voctogui/high_dpi', True):
        return {
            'kitty': {
                'fontsize': "10",
            },
        }
    else:
        return {
            'kitty': {
                'fontsize': "18.0",
            },
        }
