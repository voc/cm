# voctocore

Requires `bundle:voctomix2` to actually deploy voctomix2.

Will install and configure everything needed to run voctocore with
streaming and recording.

## metadata
```python
    'voctocore': {
        'audio': {}, # see below
        'backgrounds': {}, # TODO
        'mirror_view': False, # enable mirroring by default
        'playout': {}, # see below
        'should_be_running': True,
        'sources': {}, # see below
        'srt_publish': True, # use srt publish instead of icecast
        'static_background_image': True, # TODO
        'streaming_auth_key': 'password', # password for streaming_endpoint
        'streaming_endpoint': 'test', # streaming endpoint on ingest.c3voc.de
        'streaming_use_dynaudnorm': False, # enable dynaudnorm filter in streaming
        'vaapi': False, # use vaapi for all rendering tasks

        # Enable slide recording/streaming. Gets disabled automatically
        # if no slides source has been configured.
        'parallel_slide_recording': True,
        'parallel_slide_streaming': True,
    },
```

### sources
#### decklink sources
If you use an interlaced video mode (`1080i50` for example), bundlewrap
will automatically set `scan=psf` in voctocore config. If that is not
what you need, you can set the `scan` attribute manually to the correct
value.

Please note that bundlewrap will enforce naming of decklink sources.
Valid source names are either `slides` or match `^cam[0-9]+$`.

```python
    'voctocore': {
        'sources': {
            'cam1': {
                'devicenumber': 0, # decklink device number
                'hdmi': False, # default, use HDMI instead of SDI
                'video_mode': '1080p25',
                'volume': '1.0', # gets auto-configured, see below

                # deinterlacing options. Defaults to 'psf' if an interlaced
                # video mode has been configured. Alternatively use
                # 'interlace'.
                'scan': 'psf',
            },
        },
    },
```

#### other sources
If you set `kind` to anything other than `decklink` (the default),
bundlewrap will disable any automatic processing of the source
configuration and simply dump anything you add to the voctocore
configuration.

Please note audio configuration still applies (see below).
Source name enforcement is disabled for non-decklink sources.

```python
    'voctocore': {
        'sources': {
            'test': {
                'kind': 'test',
                'volume': '1.0', # gets auto-configured, see below
                # Any other options are put into the config as stated.
            },
        },
    },
```

### audio
Bundlewrap will take care of configuring the sources and blinders correctly.
If you don't set it, the `volume` attribute of the corresponding input
will automatically be set to `1.0`. If you want to change this, you have
to manually set the `volume` attribute of the audio stream to the correct
value.

```python
    'voctocore': {
        'audio': {
            'original': {
                'input': 'cam1', # voctocore source name
                'streams': '0+1', # audio stream number
                'volume': '1.0', # default
            },
        },
    },
```

### playout
If you want to send content out of one of the decklink cards, you can
do so using the `voctocore/playout` metadata key.

You have to use a source name as key, the value is the decklink device
number. You may also use the special value `fb` to output to the internal
HDMI output on the mainboard.

For source name, you can use any defined voctocore source name, in
addition to `program` (without stream-blanker) and `stream` (including
stream-blanker).

Bundlewrap will print an error if you try to use an invalid source name
or if you're trying to re-use decklink cards for multiple things. Please
note bundlewrap will *not* verify whether your decklink card does support
playout.

When using `fb` output, you have to have a display connected to the
encoder during boot, otherwise `/dev/fb0` won't get created correctly.

```python
    'voctocore': {
        'playout': {
            'cam1': '0', # playout cam1 to decklink output 0
            'stream': '1', # playout stream to decklink output 1
            'program': 'fb', # playout program to framebuffer
        },
    },
```
