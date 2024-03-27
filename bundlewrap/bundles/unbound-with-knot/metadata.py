from bundlewrap.metadata import atomic

defaults = {
    'apt': {
        'packages': {
            'dns-root-data': {},
            'gpg': {},
            'knot': {},
            'unbound': {},
            'unbound-anchor': {},
        },
    },
    'systemd-timers': {
        'timers': {
            'knot_update': {
                'command': '/etc/knot/update.sh',
                'when': f'*-*-* *:{node.magic_number%60}:00',
                'requires': {
                    'network-online.target',
                },
            },
        },
    },
    'unbound-with-knot': {
        'knot_zones': {
            # list of zones that should get redirected to knot
            'c3voc.de',
        },
        'max_ttl': 3600,
        'cache_size': '512M',
    },
}


@metadata_reactor.provides(
    'firewall/port_rules',
)
def firewall(metadata):
    return {
        'firewall': {
            'port_rules': {
                # nope. nothing for knot
                '53/tcp': atomic(metadata.get('unbound/restrict-to', set())),
                '53/udp': atomic(metadata.get('unbound/restrict-to', set())),
            },
        },
    }
