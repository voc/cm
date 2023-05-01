# pygtk-atem-switcher

Provides a GTK-based UI to switch inputs on a network connected ATEM
mini.

## metadata

```python
    'pygtk-atem-switcher': {
        'atem': {
            'ip': '10.73.1.40', # derived by room number
            'video_mode': '1080p25', # this is the default
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
```

The set video mode will be enforced on start-up.
