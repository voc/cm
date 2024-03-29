from math import ceil

defaults = {
    'loudness-viewer': {
        'screen': {
            'width': 1920,
            'height': 1080,
        },
    },
}


@metadata_reactor.provides(
    'loudness-viewer/streams',
    'loudness-viewer/terminal',
)
def gather_from_other_node(metadata):
    n = metadata.get('loudness-viewer/streams_from_node', None)
    if not n:
        return {}

    rnode = repo.get_node(n)
    streams = {}
    x = 0
    for idx, (name, stream) in enumerate(sorted(rnode.metadata.get('loudness-rendering').items())):
        streams[f'stream_{name}'] = {
            'command': f'/usr/local/bin/mpv.sh stream_{name} {stream}',
            'height': 540,
            'width': 480,
            'x': x,
            'y': 0 if idx % 2 == 0 else 540,
        }
        if idx % 2 > 0:
            x += 480

    stream_width = ceil(len(streams)/2)*480
    return {
        'loudness-viewer': {
            'streams': streams,
            'terminal': {
                'height': metadata.get('loudness-viewer/screen/height'),
                'width': metadata.get('loudness-viewer/screen/width')-stream_width,
                'x': stream_width,
                'y': 0,
            },
        },
    }
