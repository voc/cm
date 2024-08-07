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
This script requires the `voc2alert` script to be available in `$PATH`
and executable (chmod +x) to send alerts.

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
