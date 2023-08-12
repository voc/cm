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
)
def enable_radvd_if_ipv6_available(metadata):
    radvd_interfaces = set(metadata.get('radvd/interfaces'))
    radvd_enabled = False

    for iface, iconfig in metadata.get('interfaces').items():
        if iface in radvd_interface:
            # ignore interfaces for which we'll do announcements for
            continue

        if iconfig.get('dhcp', False):
            # ignore interfaces for which we do dhcp client
            continue

        for ip in iconfig.get('ips', set()):
            if ip_network(ip, strict=False).version == 6:
                radvd_enabled = True

    return {
        'radvd': {
            'is_enabled': radvd_enabled,
        },
    }
