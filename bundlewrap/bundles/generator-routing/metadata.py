from bundlewrap.exceptions import BundleError
from ipaddress import ip_address

@metadata_reactor.provides(
    'external_interface',
    'internal_interfaces',
    'nftables/forward/10-generator-routing',
    'nftables/postrouting/10-generator-routing',
    'sysctl/options'
)
def generator_routing(metadata):
    external_interface = metadata.get('external_interface', None)
    interfaces = metadata.get('interfaces')

    if not external_interface:
        for iface, iconfig in interfaces.items():
            this_is_external = iconfig.get('dhcp', False) == True
            for ip in iconfig['ips']:
                i = ip_address(ip.split('/')[0])
                if i.is_global:
                    this_is_external = True
            if this_is_external:
                if external_interface:
                    raise BundleError(
                        f'{node.name}: Interfaces {external_interface} and {iface} both have '
                        'public ip addresses! Please specify which is the external interface '
                        'using metadata "external_interface" manually!'
                    )
                external_interface = iface

    internal_interfaces = set(interfaces) - {external_interface}

    nftables_forward = {
        'ct state { related, established } accept',
    }
    nftables_postrouting = {
        f'oifname {external_interface} masquerade',
    }
    sysctl_options = {
        'net.ipv4.conf.all.forwarding': '1',
        'net.ipv6.conf.all.forwarding': '1',
        'net.ipv6.conf.all.disable_ipv6': '0',
    }

    for interface in internal_interfaces:
        nftables_forward.add(f'iifname {interface} accept')

    return {
        'external_interface': external_interface,
        'internal_interfaces': internal_interfaces,
        'nftables': {
            'forward': {
                '10-generator-routing': sorted(nftables_forward),
            },
            'postrouting': {
                '10-generator-routing': sorted(nftables_postrouting),
            },
        },
        'sysctl': {
            'options': sysctl_options,
        },
    }
