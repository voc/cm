from bundlewrap.metadata import atomic

defaults = {
    'apt': {
        'packages': {
            'netdata': {},
        },
    },
}

@metadata_reactor.provides(
    'firewall/port_rules',
)
def firewall(metadata):
    return {
        'firewall': {
            'port_rules': {
                '19999/tcp': atomic(metadata.get('netdata/restrict-to', set())),
            },
        },
    }
