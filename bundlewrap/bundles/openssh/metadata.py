from bundlewrap.metadata import atomic

defaults = {
    'apt': {
        'packages': {
            'openssh-client': {},
            'openssh-server': {},
            'openssh-sftp-server': {},
        },
    },
    'pacman': {
        'packages': {
            'openssh': {},
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
                '22': atomic(metadata.get('openssh/restrict-to', {'*'})),
            },
        },
    }
