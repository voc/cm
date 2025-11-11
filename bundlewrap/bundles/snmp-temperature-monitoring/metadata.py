defaults = {
    'apt': {
        'packages': {
            'snmp': {},
        },
    },
}


@metadata_reactor.provides(
    'snmp-temperature-monitoring/routeros',
)
def auto_routeros(metadata):
    room = metadata.get('room_number', None)
    if not room:
        return {}

    nodes = repo.nodes_in_all_groups([
        f'saal{room}',
        'switches-mikrotik',
    ])
    if not nodes:
        return {}

    return {
        'snmp-temperature-monitoring': {
            'routeros': {
                rnode.hostname
                for rnode in nodes
            },
        },
    }
