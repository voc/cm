# snmp-temperature-monitoring

Alerts operators about devices exceeding the specified operating
temperature.

Currently temperature limits are hardcoded at 75°C/80°C (warn/error) for
ComWare 5 devices, and 80°C/90°C for RouterOS devices.

For ComWare 5 devices, stacks up to three devices will be monitored.

```toml
[metadata.snmp-temperature-monitoring]
# list of hostnames of devices running Mikrotik RouterOS
routeros = ["switch-routeros.example.com"]

# list of hostnames of devices running HP ComWare 5
comware5 = ["switch-comware5.example.org"]
```
