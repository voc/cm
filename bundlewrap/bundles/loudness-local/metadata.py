from bundlewrap.exceptions import BundleError

defaults = {
    'apt': {
        'packages': {
            'ffmpeg': {},
        },
    },
    'systemd-timers': {
        'timers': {
            'loudness_info_updater': {
                'command': '/usr/local/bin/loudness_info_updater',
                'when': 'minutely',
            },
        },
    },
}


@metadata_reactor.provides(
    'loudness-rendering/streams',
)
def from_encoders(metadata):
    streams = {}
    for encoder in metadata.get('loudness-rendering/from_encoders', set()):
        rnode = repo.get_node(encoder)
        if not rnode.has_bundle('voctocore'):
            raise BundleError(f'{node.name}: loudness rendering requested for {encoder}, but is missing bundle:voctocore')
        endpoint = rnode.metadata.get('voctocore/streaming_endpoint')
        streams[encoder] = {
            'source': f'tcp://{encoder}.lan.c3voc.de:15000',
            'room': rnode.metadata.get('event/room_name'),
            'output': f'rtmp://ingest2.c3voc.de/relay/{endpoint}_loudness_local',
        }
    return {
        'loudness-rendering': {
            'streams': streams,
        },
    }
