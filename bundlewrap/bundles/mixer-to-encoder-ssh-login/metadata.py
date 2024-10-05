from bundlewrap.exceptions import NoSuchGroup

@metadata_reactor.provides(
    'users/voc/ssh_config_verbatim/mixer-to-encoder-ssh-login',
)
def ssh_config_generator(metadata):
    room_number = metadata.get('room_number', None)
    if room_number is None:
        return {}

    try:
        saal_nodes = repo.nodes_in_group(f'saal{room_number}')
    except NosuchGroup:
        return {}

    ssh_hostnames = set()
    for rnode in saal_nodes:
        if rnode.name == node.name:
            continue

        ssh_hostnames.add(rnode.name)
        ssh_hostnames.add(rnode.hostname)
        ssh_hostnames.add(rnode.metadata.get('hostname'))

    return {
        'users': {
            'voc': {
                'ssh_config_verbatim': {
                    'mixer-to-encoder-ssh-login': ssh_hostnames,
                },
            },
        },
    }
