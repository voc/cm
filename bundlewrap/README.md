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

To set a room name, simply edit the room_name value in `nodes/yourencoder.toml`:

```toml
[metadata.event]
room_name = "myroom"
```

It is important that you never commit `yourevent.toml` to the main branch
of this repository.

## Custom artwork

Using this repository, you can deploy room-specific or event-specific (or a mixture of both) artwork to the encoders.

Place your artwork into `data/voctocore-artwork/files/<event_slug>/` for event-specific artwork, into `data/voctocore-artwork/files/<event_slug>/saal<number>/` for room-specific artwork.

Room-specific artwork will take preference over event-specific artwork. In case neither is found, bundlewrap will use the generic VOC artwork.
