# c3voc Bundlewrap Repository (DEMO ONLY, NO PRODUCTION USE!)

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

You should also deploy the `.secrets.cfg` file to the same directory
this README lives in. This will allow you to apply anything on the
machines.

## Event setup

To set up a new event, do the following steps, add `yourevent.toml` to
the `groups` directory in this repository. That file should contain the
basic information about your event:

```toml
subgroups = ["saal1", "saal2"]

[metadata.event]
timezone = "Europe/Berlin"
acronym = "XYZ"
name = "ZYXcon"
slogan = ""
```

Please add the rooms used in your event to the `subgroups` list of the
file.

It is important that you never commit `yourevent.toml` to the main branch
of this repository.
