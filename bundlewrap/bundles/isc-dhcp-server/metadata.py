from json import load
from os.path import join


with open(join(repo.path, 'configs', 'dhcp.json')) as f:
    allocs = load(f)

defaults = {
    'apt': {
        'packages': {
            'isc-dhcp-server': {},
        },
    },
    'bash_aliases': {
        'leases': 'sudo dhcp-lease-list | tail -n +4 | sort -k 2,2',
    },
    'isc-dhcp-server': {
        'fixed_allocations': allocs,
    },
}


@metadata_reactor.provides(
    'nftables/input/10-dhcpd',
)
def nftables(metadata):
    rules = set()
    for iface in node.metadata.get('isc-dhcp-server/subnets', {}):
        rules.add(f'udp dport {{ 67, 68 }} iifname {iface} accept')

    return {
        'nftables': {
            'input': {
                # can't use port_rules here, because we're generating interface based rules.
                '10-dhcpd': sorted(rules),
            },
        }
    }
