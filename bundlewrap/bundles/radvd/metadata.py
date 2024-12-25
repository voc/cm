from ipaddress import ip_network

defaults = {
    'apt': {
        'packages': {
            'radvd': {},
        },
    },
}

@metadata_reactor.provides(
    'radvd/is_enabled',
    'unit-status-on-login',
)
def enable_radvd_if_ipv6_available(metadata):
    radvd_interfaces = set(metadata.get('radvd/interfaces'))
    radvd_enabled = False

    for iface, iconfig in metadata.get('interfaces').items():
        # Ignore interfaces if one of the following conditions are met:
        # - Interface gets router advertisements by us
        # - Interface uses DHCP
        # - Interface has no IPv6 gateway set
        if (
            iface in radvd_interfaces
            or iconfig.get('dhcp', False)
            or not iconfig.get('gateway6')
        ):
            continue

        for ip in iconfig.get('ips', set()):
            if ip_network(ip, strict=False).version == 6:
                radvd_enabled = True

    return {
        'radvd': {
            'is_enabled': radvd_enabled,
        },
        'unit-status-on-login': {
            'radvd',
        } if radvd_enabled else set(),
    }
