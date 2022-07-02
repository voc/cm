import bwkeepass as keepass

event = node.metadata.get('event/acronym', '')
assert node.has_bundle('encoder-common')

slides_port = 0
for idx, sname in enumerate(node.metadata.get('voctocore/sources', {})):
    if sname == 'slides':
        slides_port = 13000 + idx

### voc2mix
directories['/opt/voctomix2/release'] = {}
git_deploy['/opt/voctomix2/release'] = {
    'repo': 'https://c3voc.de/git/voctomix',
    'rev': 'voctomix2',
}
files['/opt/voctomix2/voctocore-config.ini'] = {
    'content_type': 'mako',
    'context': {
        'audio': node.metadata.get('voctocore/audio', {}),
        'backgrounds': node.metadata.get('voctocore/backgrounds', {}),
        'event': event,
        'mirror_view': node.metadata.get('voctocore/mirror_view'),
        'room_name': node.metadata.get('event/room_name', ''),
        'sources': node.metadata.get('voctocore/sources', {}),
        'static_background_image': node.metadata.get('voctocore/static_background_image'),
        'vaapi_enabled': node.metadata.get('voctocore/vaapi'),
    },
    'triggers': {
        'svc_systemd:voctomix2-voctocore:restart',
    },
}
files['/usr/local/lib/systemd/system/voctomix2-voctocore.service'] = {
    'triggers': {
        'action:systemd-reload',
        'svc_systemd:voctomix2-voctocore:restart',
    },
}
svc_systemd['voctomix2-voctocore'] = {
    'needs': {
        'file:/opt/voctomix2/voctocore-config.ini',
        'file:/usr/local/lib/systemd/system/voctomix2-voctocore.service',
        'git_deploy:/opt/voctomix2/release',
        'pkg_apt:'
    },
    'tags': {
        'causes-downtime',
    },
}


### Monitoring
files['/usr/local/sbin/check_system.d/check_recording.pl'] = {
    # will get executed automatically by bundle:mqtt-monitoring
    'mode': '0755',
}


### Additional scripts
directories['/opt/voctomix2/scripts'] = {
    'purge': True,
}

## recording-sink
files['/opt/voctomix2/scripts/recording-sink.sh'] = {
    'content_type': 'mako',
    'context': {
        'event': node.metadata.get('event'),
        'mqtt': node.metadata.get('mqtt-monitoring'),
        'parallel_slide_recording': node.metadata.get('voctocore/parallel_slide_recording'),
        'slides_port': slides_port,
    },
    'mode': '0755',
    'triggers': {
        'svc_systemd:voctomix2-recording-sink:restart',
    },
}
files['/usr/local/lib/systemd/system/voctomix2-recording-sink.service'] = {
    'triggers': {
        'action:systemd-reload',
        'svc_systemd:voctomix2-recording-sink:restart',
    },
}
svc_systemd['voctomix2-recording-sink'] = {
    'needs': {
        'file:/opt/voctomix2/scripts/recording-sink.sh',
        'file:/usr/local/lib/systemd/system/voctomix2-recording-sink.service',
        'pkg_apt:ffmpeg'
    },
    'tags': {
        'causes-downtime',
    },
}

## streaming sink

files['/opt/voctomix2/scripts/streaming-sink.sh'] = {
    'content_type': 'mako',
    'context': {
        'event': node.metadata.get('event'),
        'parallel_slide_streaming': node.metadata.get('voctocore/parallel_slide_streaming'),
        'slides_port': slides_port + 2000,
        'srt_publish': node.metadata.get('voctocore/srt_publish'),
        'endpoint': node.metadata.get('voctocore/streaming_endpoint'),
        'icecast_key': keepass.password(['ansible', 'icecast', 'source']),
        'vaapi_enabled': node.metadata.get('voctocore/vaapi'),
    },
    'mode': '0755',
    'triggers': {
        'svc_systemd:voctomix2-streaming-sink:restart',
    },
}
files['/usr/local/lib/systemd/system/voctomix2-streaming-sink.service'] = {
    'triggers': {
        'action:systemd-reload',
        'svc_systemd:voctomix2-streaming-sink:restart',
    },
}
svc_systemd['voctomix2-streaming-sink'] = {
    'needs': {
        'file:/opt/voctomix2/scripts/streaming-sink.sh',
        'file:/usr/local/lib/systemd/system/voctomix2-streaming-sink.service',
        'pkg_apt:ffmpeg'
    },
    'tags': {
        'causes-downtime',
    },
}
