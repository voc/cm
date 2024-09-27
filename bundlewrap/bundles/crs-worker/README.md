# crs-worker scripts

Installs and configures the CRS worker scripts and generates
`/home/voc/.ssh/upload-key`.

```toml
[metadata.crs-worker]
postprocessing_dummy_instead_of_upload = false # default
number_of_encoding_workers = 1 # default
autostart_scripts = [] # list of worker scripts to start on boot
tracker_url = "https://tracker.example.org/rpc" # url for the crs tracker XML-RPC api
use_vaapi = false # should the workers expose the CRS_USE_VAAPI environment variable
room_name = "Example Room" # sets CRS_ROOM environment variable for room-specific tasks
```

Available worker scripts are:

* recording-scheduler
* mount4cut
* cut-postprocessor
* postencoding
* autochecker
* postprocessing

Depending on the amount of encoding workers you requested using
`number_of_encoding_workers`, you also either get the `encoding` script
or enumerated encoding scripts starting at 0 (`encoding0`, `encoding1`,
... `encodingN`).

## secrets

```toml
[metadata.crs-worker.secrets.encoding]
token = "example"
secret = "secret"

[metadata.crs-worker.secrets.meta]
token = "example"
secret = "secret"
```

Most worker scripts will use the `meta` secrets, only the encoding
script(s) will use the encoding script. The `autochecker` script will
use the `autochecker` secrets.

If not specified, the `meta` secret will get derived from the `encoding`
secret, so you only have to specify that if they are the same.

Scripts for which no secrets are configured will not be available on the
system. An error will get raised if a script is requested to be
autostarted, but no secrets are configured.

## rsync script(s)

This bundle will also deploy the `rsync-from-encoder@` template unit.
This allows the system designated as storage system to easily pull
recordings of the currently configured event onto itself.

If you really need it, you can also enable deployment of the
`rsync-to-storage@` systemd unit to start a rsync process on the encoder
side. There is no automation for deploying ssh keys in this case, you
have to do that yourself.
