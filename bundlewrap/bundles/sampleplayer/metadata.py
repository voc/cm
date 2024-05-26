defaults = {
    'apt': {
        'packages': {
            'alsa-utils': {},
            'alsa-tools': {},
            'gunicorn': {},
        },
    },
    'sampleplayer': {
        'rev': 'main',
        'sources': [
            'voc-internal',
            "voc-vpn",
        ],
    },
}

@metadata_reactor.provides(
    'firewall/port_rules',
)
def sperrfix(metadata):
    if metadata.get('sampleplayer/firewall/ignore', False):
        return {}

    sources = metadata.get('sampleplayer/sources', set())

    return {
        "firewall": {
            "port_rules": {
                "8080/tcp": sources,
            },
        },
    }
