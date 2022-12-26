# c3voc Bundlewrap Repository

Setting up this repository is easy:

```
pip3 install -r requirements.txt
```

You do not need to set up Keepass or a bundlewrap .secrets.cfg for basic
encoder setup.

If you have access to the c3voc keepass file, you may want to set up a
bit more stuff:

```
export BW_KEEPASS_FILE=$HOME/whereever/the/voc/keepass/lives.kdbx
export BW_KEEPASS_PASSWORD=reallysecure
```

You want to set up ssh multiplexing for fast runs:
```
Host *
    ControlPath ~/.ssh/cm-%r@%h:%p
    ControlMaster auto
    ControlPersist 10m
```

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
of this repository.

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
number.

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
