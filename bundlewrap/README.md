# c3voc Bundlewrap Repository

Setting up this repository is easy:

```
pip3 install -r requirements.txt
```

You do not need to set up Keepass or a bundlewrap .secrets.cfg for basic
encoder setup.

If you have access to the c3voc keepass file, you may want to set up
keepass and the .secrets.cfg:

```
export BW_KEEPASS_FILE=$HOME/whereever/the/voc/keepass/lives.kdbx
export BW_KEEPASS_PASSWORD=reallysecure
```

The contents of the .secrets.cfg file can be found in the keepass file,
too.

You want to set up ssh multiplexing for fast runs:
```
Host *
    ControlPath ~/.ssh/cm-%r@%h:%p
    ControlMaster auto
    ControlPersist 10m
```

## Usage

These are just some examples, please refer to the
[bundlewrap documentation](https://docs.bundlewrap.org/guide/cli/)
for more information.

```
# apply configuration to system(s), restarting services as needed
$ bw apply <system or group>

# apply configuration to system(s), skipping all restarts that would
# interrupt a stream or recording
$ bw apply -s tag:causes-downtime -- <system or group>

# apply configuration to system(s), but ask before doing any change, so
# you can decide if you really want to do the change
$ bw apply -i <system or group>

# dry-run, show all changes an apply would do, without doing any actual
# changes on the system
$ bw verify <system or group>

# verify configuration for a system locally
# if you don't have keepass access, you have to append -i flag
$ bw test <system or group>
```

`<system or group>` can be a single system name, like `encoder1` or
a group of systems, like `saal1`. The saal groups contain all systems
in that case (encoder, minion, mixer, all tally pis).

## Event setup

To set up a new event, do the following steps, add `yourevent.toml` to
the `groups` directory in this repository. That file should contain the
basic information about your event:

```toml
subgroups = ["saal1", "saal2"]

[metadata.event]
timezone = "Europe/Berlin"
name = "ZYXcon"
slug = "XYZ"
```

Please add the rooms used in your event to the `subgroups` list of the
file.

Available room setups:
* saal1
* saal2
* saal3
* saal4
* saal5
* saal6
* saal23
* saal80
* saal81
* saal191
* servercase

To set a room name, simply edit the `room_name` value in `nodes/yourencoder.toml`:

```toml
[metadata.event]
room_name = "myroom"
```

It is important that you never commit `yourevent.toml` to the main branch
of this repository. Instead, please create a branch named `events/XYZ`,
replacing `XYZ` with your event slug.

### Overlays

If you want to use overlays ("Bauchbinden" in German), you have to add
the key `overlays` to `yourevent.toml`. The value of this key should be
a full-blown URL pointing to a `.tar.gz`-Archive containing the overlays
themselves. You can create it using `tar -czf overlays.tar.gz *.png`.

If the event uses a `schedule.xml` file, you can add it to the config
using the `schedule_xml` key. This needs to be a URL, too.

If the event does not use a schedule, you can specify
filename-to-title-Mappings yourself. You can do so using the
`event/overlay_mapping` metadata key.

If you provide a schedule.xml and `event/overlay_mapping`, the schedule
will take preference.

#### Example config

```toml
[metadata.event]
schedule_xml = "https://example.com/schedule.xml"
overlays = "https://example.com/overlays.tar.gz"

[metadata.event.overlay_mappings]
# Omit ".png" from filename here
graphic1 = "Alice"
graphic2 = "Bob"
graphic3 = "Alice and Bob"
```

### Custom artwork

Using this repository, you can deploy room-specific or event-specific
(or a mixture of both) artwork to the encoders.

Place your artwork into `data/voctocore-artwork/files/<event_slug>/`
for event-specific artwork, into
`data/voctocore-artwork/files/<event_slug>/saal<number>/` for
room-specific artwork.

Room-specific artwork will take preference over event-specific artwork.
In case neither is found, bundlewrap will use the generic VOC artwork.


### voctocore playout

If you want to send content out of one of the decklink cards, you can
do so using the `voctocore/playout` metadata key.

You have to use a source name as key, the value is the decklink device
number. You may also use the special value `fb` to output to the internal
HDMI output on the mainboard.

```toml
[metadata.voctocore.playout]
program = 0
stream = 1
cam1 = 4
```

For source name, you can use any defined voctocore source name, in
addition to `program` (without stream-blanker) and `stream` (including
stream-blanker).

Bundlewrap will print an error if you try to use an invalid source name
or if you're trying to re-use decklink cards for multiple things. Please
note bundlewrap will *not* verify whether your decklink card does support
playout.

When using `fb` output, you have to have a display connected to the
encoder during boot, otherwise `/dev/fb0` won't get created correctly.

### ATEM Mini

Bundlewrap will deploy
[pygtk-atem-switcher](https://github.com/kunsi/pygtk-atem-switcher) to
each mixer laptop.

If your ATEM is not reachable at `10.73.<room>.40`, please set the
metadata `pygtk-atem-switcher/atem/ip` to the correct ip address.

pygtk-atem-switcher will enforce some settings on startup to ensure
smooth operation in all cases. To change these settings, add the
following metadata to the `nodes/yourmixer.toml` file.

If you wish to hide an input from the software, set its name to `empty`
or `x`.

```toml
# All those values represent the defaults set by bundlewrap
[metadata.pygtk-atem-switcher.atem]
video_mode = "1080p25"

[metadata.pygtk-atem-switcher.atem.settings.inputs]
input1 = "Laptop"
input2 = "x"
input3 = "x"
input4 = "info-beamer"
```

## voctocore Sources Defitinion

### video

#### decklink inputs

```toml
[metadata.voctocore.sources.cam2] # "cam2" is the source name
devicenumber = 2 # decklink device number
mode = "1080p25" # video mode
hdmi = true # default false. If true, uses HDMI instead of SDI
```

If you use an interlaced video mode (`1080i50` for example), bundlewrap
will automatically set `scan=psf` in voctocore config. If that is not
what you need, you can set the `scan` attribute manually to the correct
value.

Please note that bundlewrap will enforce naming of decklink sources.
Valid source names are either `slides` or match `^cam[0-9]+$`.

#### other inputs

```toml
[metadata.voctocore.sources.balltest]
kind = "test"
pattern = "ball"
```

If you set `kind`, bundlewrap will disable any automatic processing of
the source configuration and simply dump anything you add to the
voctocore configuration.

Please note audio configuration still applies (see below).
Source name enforcement is disabled for non-decklink sources.

### audio

```toml
[metadata.voctocore.audio.translated-1] # "translated-1" is the source name
input = "cam1" # which input provides this audio
streams = "0+1" # use the first two audio streams received by the input
volume = "1,0" # this is the default
```

Bundlewrap will take care of configuring the sources and blinders correctly.
If you don't set it, the `volume` attribute of the corresponding input
will automatically be set to `1.0`. If you want to change this, you have
to manually set the `volume` attribute of the audio stream to the correct
value.
