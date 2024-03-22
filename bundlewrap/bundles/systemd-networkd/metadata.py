defaults = {
    'apt': {
        'packages': {
            'resolvconf': {
                'installed': False,
            },
        },
    },
}


@metadata_reactor.provides(
    'interfaces',
)
def add_vlan_infos_to_interface(metadata):
    interfaces = {}

    for iface in metadata.get('interfaces', {}):
        if '.' not in iface:
            continue

        interface,vlan = iface.split('.')

        interfaces.setdefault(interface, {}).setdefault('vlans', set())
        interfaces[interface]['vlans'].add(vlan)

    return {
        'interfaces': interfaces,
    }


@metadata_reactor.provides(
    'nftables/forward/10-wireguard-tunnels',
)
def wireguard_forwarding(metadata):
    rules = set()
    for tunnel in metadata.get('systemd-networkd/wireguard', {}):
        rules.add(f'iifname wg_{tunnel} accept')
        rules.add(f'oifname wg_{tunnel} accept')
    return {
        'nftables': {
            'forward': {
                '10-wireguard-tunnels': sorted(rules),
            },
        },
    }
