from bundlewrap.metadata import atomic

defaults = {
    'apt': {
        'packages': {
            'samba': {},
        }
    }
}

@metadata_reactor.provides(
    'firewall/port_rules/22',
)
def firewall(metadata):
    if metadata.get('samba/restrict-to/ignore'):
        return {}
    else:
        return {
            'firewall': {
                'port_rules': {
                    '137/udp': atomic(metadata.get('samba/restrict-to', {'*'})),
                    '138/udp': atomic(metadata.get('samba/restrict-to', {'*'})),
                    '139': atomic(metadata.get('samba/restrict-to', {'*'})),
                    '445': atomic(metadata.get('samba/restrict-to', {'*'})),
                },
            },
        }
