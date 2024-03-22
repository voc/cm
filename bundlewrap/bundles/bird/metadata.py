from ipaddress import ip_network

from bundlewrap.exceptions import NoSuchNode
from bundlewrap.metadata import atomic

defaults = {
    'apt': {
        'packages': {
            'bird2': {},
        },
    },
    'sysctl': {
        'options': {
            'net.ipv4.conf.all.forwarding': '1',
            'net.ipv6.conf.all.forwarding': '1',
        },
    },
}


@metadata_reactor.provides(
    'bird/my_ip',
)
def my_ip(metadata):
    wg_tunnels = sorted(metadata.get('systemd-networkd/wireguard', {}).keys())
    if wg_tunnels:
        my_ip = metadata.get(f'systemd-networkd/wireguard/{wg_tunnels[0]}/my_ip').split('/')[0]
    else:
        my_ip = str(sorted(repo.libs.tools.resolve_identifier(repo, node.name))[0])

    return {
        'bird': {
            'my_ip': my_ip,
        },
    }


@metadata_reactor.provides(
    'firewall/port_rules',
)
def firewall(metadata):
    sources = set()
    for config in metadata.get('bird/bgp_neighbors', {}).values():
        sources.add(config['neighbor_ip'])

    return {
        'firewall': {
            'port_rules': {
                '179': atomic(sources),
            },
        },
    }
