from bundlewrap.metadata import atomic

defaults = {
    'apt': {
        'packages': {
            'netdata': {},
        },
    },
}

@metadata_reactor.provides(
    'firewall/port_rules/22',
)
def firewall(metadata):
    return {
        'firewall': {
            'port_rules': {
                '1999': atomic(metadata.get('netdata/restrict-to', set())),
            },
        },
    }
