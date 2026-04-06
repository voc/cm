defaults = {
    'pygtk-atem-switcher': {
        'atem': {
            'video_mode': '1080p50',
            'settings': {
                'inputs': {
                    'input1': 'Laptop',
                    'input2': 'x',
                    'input3': 'x',
                    'input4': 'info-beamer',
                    'color1': 'x',
                    'color2': 'x',
                    'colorBars': 'x',
                },
            },
        },
        'logging': {
            'level': 'INFO',
            'format': '%(name)25s [%(levelname)-8s] %(message)s',
        },
        'gtk-settings': {
            'gtk-theme-name': 'Adwaita',
            'gtk-application-prefer-dark-theme': True,
        },
    },
    'unit-status-on-login': {
        'pygtk-atem-switcher',
    },
}

@metadata_reactor.provides(
    'pygtk-atem-switcher/atem/ip',
)
def atem_ip(metadata):
    return {
        'pygtk-atem-switcher': {
            'atem': {
                'ip': '10.73.{}.40'.format(metadata.get('room_number', 0)),
            },
        },
    }

@metadata_reactor.provides(
    'pygtk-atem-switcher/atem/settings/inputs/settings/inputs/mediaPlayer1',
)
def atem_enable_logo(metadata):
    return {
        'pygtk-atem-switcher': {
            'atem': {
                'settings': {
                    'inputs': {
                        'mediaPlayer1': 'Event Logo' if metadata.get('atem/enable_logo') else 'x'
                    }
                }
            }
        }
    }
