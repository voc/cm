from bundlewrap.metadata import atomic

defaults = {
    'apt': {
        'packages': {
            'samba': {},
            'samba-vfs-modules': {},
        }
    }
}


@metadata_reactor.provides(
    'firewall/port_rules',
)
def firewall(metadata):
    return {
        'firewall': {
            'port_rules': {
                '137/udp': atomic(metadata.get('samba/restrict-to', set())),
                '138/udp': atomic(metadata.get('samba/restrict-to', set())),
                '139/tcp': atomic(metadata.get('samba/restrict-to', set())),
                '445/tcp': atomic(metadata.get('samba/restrict-to', set())),
            },
        },
    }
