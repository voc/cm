from bundlewrap.metadata import atomic

defaults = {
    'apt': {
        'repos': {
            'nginx': {
                'items': {
                    'deb http://nginx.org/packages/{os} {os_release} nginx',
                },
            },
        },
        'packages': {
            'nginx': {},
        },
    },
    'nginx': {
        'worker_connections': 768,
        'worker_processes': 4,
    },
    'pacman': {
        'packages': {
            'nginx': {},
        },
    },
}

if node.has_bundle('telegraf'):
    defaults['telegraf'] = {
        'input_plugins': {
            'builtin': {
                'nginx': [{
                    'urls': ['http://localhost:22999/server_status'],
                }],
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
                '80/tcp': atomic(metadata.get('nginx/restrict-to', {'*'})),
                '443/tcp': atomic(metadata.get('nginx/restrict-to', {'*'})),
            },
        },
    }
