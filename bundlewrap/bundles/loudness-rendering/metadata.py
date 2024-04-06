from bundlewrap.exceptions import BundleError

defaults = {
    'apt': {
        'packages': {
            'ffmpeg': {},
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
            'source': f'https://cdn.c3voc.de/hls/{endpoint}/native_hd.m3u8',
            'room': rnode.metadata.get('event/room_name'),
            'output': f'rtmp://ingest2.c3voc.de/relay/{endpoint}_loudness',
        }
    return {
        'loudness-rendering': {
            'streams': streams,
        },
    }
