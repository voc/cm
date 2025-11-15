from ipaddress import ip_address, ip_network
from json import load
from os.path import join
from re import sub as re_sub


with open(join(repo.path, 'configs', 'dhcp.json')) as f:
    allocs = load(f)

defaults = {
    'apt': {
        'packages': {
            'kea-dhcp4-server': {},
            'isc-dhcp-server': {
                'installed': False,
            },
        },
    },
    'kea-dhcp-server': {
        'config': {
            'authoritative': True,
            'rebind-timer': 450,
            'renew-timer': 300,
            'valid-lifetime': 600,
            'expired-leases-processing': {
                'max-reclaim-leases': 0,
                'max-reclaim-time': 0,
            },
            'lease-database': {
                'lfc-interval': 3600,
                'name': '/var/lib/kea/kea-leases4.csv',
                'persist': True,
                'type': 'memfile',
            },
        },
    },
}


@metadata_reactor.provides(
    'kea-dhcp-server/fixed_allocations',
)
def get_static_allocations(metadata):
    result = {}
    mapping = {}

    for iface, config in metadata.get('kea-dhcp-server/subnets', {}).items():
        result[iface] = {}
        mapping[iface] = ip_network(config['subnet'])

    for ip, allocation in allocs.items():
        ipaddr = ip_address(ip)

        for kea_iface, kea_subnet in mapping.items():
            if ipaddr in kea_subnet:
                result[kea_iface][re_sub(r'[^a-z0-9]+', '-', allocation['description'].lower()).strip('-')] = {
                    'ip': ip,
                    'mac': allocation['mac'],
                }
                break

    return {
        'kea-dhcp-server': {
            'fixed_allocations': result,
        }
    }


@metadata_reactor.provides(
    'kea-dhcp-server/subnets',
)
def subnet_id(metadata):
    subnets = {}

    for iface, config in metadata.get('kea-dhcp-server/subnets', {}).items():
        vlan_id = iface.split('.')[-1]
        if vlan_id.isdigit():
            subnets[iface] = {
                'id': vlan_id,
            }

    return {
        'kea-dhcp-server': {
            'subnets': subnets,
        }
    }


@metadata_reactor.provides(
    'nftables/input/10-kea-dhcp-server',
)
def nftables(metadata):
    rules = set()
    for iface in node.metadata.get('kea-dhcp-server/subnets', {}):
        rules.add(f'udp dport {{ 67, 68 }} iifname {iface} accept')

    return {
        'nftables': {
            'input': {
                # can't use port_rules here, because we're generating interface based rules.
                '10-kea-dhcp-server': sorted(rules),
            },
        }
    }
