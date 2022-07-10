from bundlewrap.metadata import atomic

defaults = {
    'apt': {
        'packages': {
            'rsync': {},
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
                '873': atomic(metadata.get('rsync/restrict-to', set())),
            },
        },
    }
