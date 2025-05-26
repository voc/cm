defaults = {
    'apt': {
        'packages': {
            'gir1.2-gtk-3.0': {},
            'gnome-themes-extra': {},
            'gstreamer1.0-alsa': {},
            'gstreamer1.0-gl': {},
            'gstreamer1.0-gtk3': {},
            'gstreamer1.0-pulseaudio': {},
            'gstreamer1.0-tools': {},
            'gstreamer1.0-vaapi': {},
            'libcairo2-dev': {},
            'libdbus-glib-1-dev': {},
            'libgirepository1.0-dev': {},
            'libgstreamer1.0-0': {},
            'librsvg2-common': {},
            'python3-dbus': {},
            'python3-dev': {},
            'python3-gi-cairo': {},
            'python3-wheel': {},
        },
    },
    'unit-status-on-login': {
        'voctomix2-voctogui',
    },
    'voctogui' : {
        'high_dpi': True,
        'play_audio': False,
        'vaapi': False,
        'video_display': 'xv',
    },
    'voctomix2': {
        'deploy_triggers': {
            'svc_systemd:voctomix2-voctogui:restart',
        },
    },
}
