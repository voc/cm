# radvd

## auto-enable

radvd will check whether any of the not configured interfaces have an
IPv6 gateway set. radvd will only get auto-enabled if that is true. To
disable radvd, you can either remove the IPv6 gateway from the system
or set `is_enabled` metadata to `False`.

## metadata

```toml
[metadata.radvd]
is_enabled = true # see above

[metadata.radvd.interfaces.eth1]
prefix = "2001:db8:10:73::/64"
rdnss = [
    "2001:db8:10:71::1",
    "2001:db8:10:71::2",
]
```
