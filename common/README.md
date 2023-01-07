# common

This directory contains files which are shared between config management
systems to ensure each system behaves the same, regardless what is used
to provision that system.

To ensure these files work as intended, each config management solution
needs to provision these files as-is with no changes. Those files
probably need some helper files/scripts. If that's the case, these
helpers are documented below, possibly including an example.

## mqtt-monitoring

Please configure your system to execute `check_system.sh` every minute.

Files in `plugins/` should be added to `/usr/local/sbin/check_system.d/`
depending on what your system does.

The `alert_shutdown.sh` script should run when shutting down the system.

### `voc2mqtt` (+x, in `$PATH`)

**Provides a way to publish mqtt messages without needing to add
authentication information.**

```bash
#!/bin/bash

mosquitto_pub \
    --capath /etc/ssl/certs/ \
    -h "${mqtt_server}" \
    -p 8883 \
    -u "${mqtt_username}" \
    -P "${mqtt_password}" \
    "$@"
```

### `voc2alert` (+x, in `$PATH`)

**Publishes alerts to the `#voc-wok` IRC channel.**

Please set `$MY_HOSTNAME` to the hostname of the system. If the system
hostname ends in `.c3voc.de`, that suffix should be removed.

```bash
#!/bin/bash

MESSAGE="$(jq \
    --null-input \
    --arg level "$1" \
    --arg component "$MY_HOSTNAME/$2" \
    --arg msg "$3" \
    --compact-output \
    '{"level": $level, "component": $component, "msg": $msg}')"

for i in 1 2 3 ; do
    voc2mqtt \
        -t '/voc/alert' \
        -m "$MESSAGE" && break
done

for i in 1 2 3 ; do
    voc2mqtt \
        -t "hosts/$MY_HOSTNAME/alert" \
        -m "$MESSAGE" && break
done
```
