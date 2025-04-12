# pygtk-atem-switcher

Provides a GTK-based UI to switch inputs on a network connected ATEM
mini.

## metadata

```toml
[metadata.pygtk-atem-switcher.atem]
ip = "10.73.1.40" # derived by room number
video_mode = "1080p50" # this is the default

[metadata.pygtk-atem-switcher.atem.settings.inputs] # these are defaults
input1 = "Laptop"
input2 = "x"
input3 = "x"
input4 = "info-beamer"
```

The set video mode will be enforced on start-up.
