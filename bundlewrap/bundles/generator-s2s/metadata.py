TUNNEL_NAME = 'c3voc'

OSPF_AREA = '10.73.0.0'
OSPF_PASSWORD = 'changeme'

@metadata_reactor.provides(
    f'bird/bgp_neighbors/wg_{TUNNEL_NAME}',
    'bird/static_routes',
    f'systemd-networkd/wireguard/{TUNNEL_NAME}',
)
def wg_and_bgp(metadata):
    room = metadata.get('room_number')
    intif = metadata.get('internal_interfaces')

    return {
        'bird': {
            'bgp_neighbors': {
                f'wg_{TUNNEL_NAME}': {
                    'local_as': 65000 + room,
                    'local_ip': f'10.9.{room}.2',
                    'neighbor_as': 65000,
                    'neighbor_ip': f'10.9.{room}.1',
                },
            },
            'static_routes': {
                f'10.73.{room}.0/24',
            },
        },
        'systemd-networkd': {
            'wireguard': {
                TUNNEL_NAME: {
                    'my_ip': f'10.9.{room}.2/30',
                    'my_port': 20000 + room,
                    'peer': f'wg.c3voc.de:{20000 + room}',
                    'peer_pubkey': metadata.get('generator-s2s/peer_pubkey'),
                    'privatekey': metadata.get('generator-s2s/privatekey'),
                },
            },
        },
    }


@metadata_reactor.provides(
    'nftables/forward/10-generator-s2s',
    'nftables/input/10-generator-s2s',
)
def firewall(metadata):
    forward = set()
    input = set()
    intif = metadata.get('internal_interfaces')

    for tunnel in metadata.get('systemd-networkd/wireguard', {}):
        forward.add(f'iifname wg_{tunnel} accept')
        input.add(f'iifname wg_{tunnel} accept')

        for iface in intif:
            forward.add(f'iifname {iface} oifname wg_{tunnel} accept')

    return {
        'nftables': {
            'forward': {
                '10-generator-s2s': sorted(forward),
            },
            'input': {
                '10-generator-s2s': sorted(input),
            },
        },
    }


@metadata_reactor.provides(
    'bird/ospf',
)
def ospf(metadata):
    raise DoNotRunAgain # TODO
    return {
        'bird': {
            'ospf': {
                'area': OSPF_AREA,
                'interfaces': {
                    metadata.get('external_interface'),
                },
                'password': OSPF_PASSWORD,
            },
        },
    }
