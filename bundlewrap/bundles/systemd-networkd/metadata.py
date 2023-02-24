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
