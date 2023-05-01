defaults = {
    'pygtk-atem-switcher': {
        'atem': {
            'video_mode': '1080p25',
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
}

@metadata_reactor.provides(
    'pygtk-atem-switcher/atem/ip',
)
def atem_ip(metadata):
    return {
        'pygtk-atem-switcher': {
            'atem': {
                'ip': '10.73.{}.40'.format(metadata.get('event/room_number', 0)),
            },
        },
    }
