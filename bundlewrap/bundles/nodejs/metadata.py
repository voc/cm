@metadata_reactor.provides(
    'apt/repos/nodejs',
    'apt/packages/nodejs',
)
def apt(metadata):
    node_version = metadata.get('nodejs/version')

    return {
        'apt': {
            'repos': {
                'nodejs': {
                    'items': [
                        f'deb https://deb.nodesource.com/node_{node_version}.x nodistro main',
                    ],
                },
            },
            'packages': {
                'nodejs': {},
            },
        },
    }
