defaults = {
    'apt': {
        'additional_update_commands': {
            # update npm to latest version
            'npm install -g yarn@latest',
        },
        'packages': {
            'nodejs': {},
        },
    },
    'nodejs': {
        'version': 18,
    },
}

VERSIONS_SHIPPED_BY_DEBIAN = {
    10: 10,
    11: 12,
    12: 18,
    13: 18,
}

@metadata_reactor.provides(
    'apt/repos/nodejs/items',
    'apt/additional_update_commands',
)
def nodejs_from_version(metadata):
    version = metadata.get('nodejs/version')

    if version != VERSIONS_SHIPPED_BY_DEBIAN[node.os_version[0]]:
        return {
            'apt': {
                'additional_update_commands': {
                    # update npm to latest version
                    'npm install -g npm@latest',
                },
                'repos': {
                    'nodejs': {
                        'items': {
                            f'deb https://deb.nodesource.com/node_{version}.x nodistro main',
                            f'deb-src https://deb.nodesource.com/node_{version}.x nodistro main',
                        },
                    },
                },
            },
        }
    else:
        return {
            'apt': {
                'packages': {
                    'npm': {},
                },
            },
        }
