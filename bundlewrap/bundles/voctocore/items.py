from bundlewrap.exceptions import BundleError
from os.path import join, isfile

KEYBOARD_SHORTCUTS = {
    # maps inputs to buttons, first for Channel A, second Channel B
    'cam1': ('F1', '1'),
    'cam2': ('F2', '2'),
    'cam3': ('F3', '3'),
    'slides': ('F4', '4'),

    # only one button for features and scenes
    'scene_fs': ('F5',),
    'scene_sbs': ('F6',),
    'scene_lec': ('F7',),
    'feature_mirror': ('F9',),
    'feature_43': ('F10',),
}

PLAYOUT_PORTS = {
    'stream': 15000,
    'program': 11000,
}

SHOULD_BE_RUNNING = node.metadata.get('voctocore/should_be_running', True)

event = node.metadata.get('event/slug')
assert node.has_bundle('encoder-common')
assert node.has_bundle('voctomix2')

slides_port = 0
for idx, sname in enumerate(node.metadata.get('voctocore/sources', {})):
    PLAYOUT_PORTS[sname] = 13000 + idx
    if sname == 'slides':
        slides_port = 13000 + idx

overlay_mapping = []
for filename, title in sorted(node.metadata.get('event/overlay_mappings', {}).items()):
    overlay_mapping.append(f'{filename}.png|{title}')

node_voctomix_path = join(repo.path, 'data', 'voctocore', 'files', f'{node.name}.ini')

### voc2mix
files['/opt/voctomix2/voctocore-config.ini'] = {
    'content_type': 'mako',
    'source': f'{node.name}.ini' if isfile(node_voctomix_path) else 'voctocore-config.ini',
    'context': {
        'audio': node.metadata.get('voctocore/audio', {}),
        'backgrounds': node.metadata.get('voctocore/backgrounds', {}),
        'event': event,
        'has_schedule': node.metadata.get('event/schedule_xml', ''),
        'keyboard_shortcuts': KEYBOARD_SHORTCUTS,
        'mirror_view': node.metadata.get('voctocore/mirror_view'),
        'overlay_mapping': overlay_mapping,
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
    'running': SHOULD_BE_RUNNING,
    'enabled': SHOULD_BE_RUNNING,
}


### Monitoring
files['/usr/local/sbin/check_system.d/check_recording.sh'] = {
    # will get executed automatically by bundle:mqtt-monitoring
    'mode': '0755',
    'content_type': 'mako',
    'context': {
        'event': node.metadata.get('event'),
    },
}
files['/usr/local/sbin/check_system.d/check_recording.pl'] = {
    'mode': '0644',
}


## recording-sink
files['/opt/voctomix2/scripts/recording-sink.sh'] = {
    'content_type': 'mako',
    'context': {
        'event': node.metadata.get('event'),
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
    'after': {
        'svc_systemd:voctomix2-voctocore',
    },
    'needs': {
        'file:/opt/voctomix2/scripts/recording-sink.sh',
        'file:/usr/local/lib/systemd/system/voctomix2-recording-sink.service',
        'pkg_apt:ffmpeg'
    },
    'tags': {
        'causes-downtime',
    },
    'running': None, # get's auto-started by svc_systemd:voctomix2-voctocore
}

## streaming-sink
files['/opt/voctomix2/scripts/streaming-sink.sh'] = {
    'content_type': 'mako',
    'context': {
        'dynaudnorm': node.metadata.get('voctocore/streaming_use_dynaudnorm'),
        'endpoint': node.metadata.get('voctocore/streaming_endpoint'),
        'event': node.metadata.get('event'),
        'parallel_slide_streaming': node.metadata.get('voctocore/parallel_slide_streaming'),
        'slides_port': slides_port,
        'srt_publish': node.metadata.get('voctocore/srt_publish'),
        'vaapi_enabled': node.metadata.get('voctocore/vaapi'),
    },
    'mode': '0755',
    'triggers': {
        'svc_systemd:voctomix2-streaming-sink:restart',
    },
}
files['/usr/local/lib/systemd/system/voctomix2-streaming-sink.service'] = {
    'content_type': 'mako',
    'context': {
        'auth_key': node.metadata.get('voctocore/streaming_auth_key'),
    },
    'cascade_skip': False,
    'triggers': {
        'action:systemd-reload',
        'svc_systemd:voctomix2-streaming-sink:restart',
    },
}
svc_systemd['voctomix2-streaming-sink'] = {
    'after': {
        'svc_systemd:voctomix2-voctocore',
    },
    'needs': {
        'file:/opt/voctomix2/scripts/streaming-sink.sh',
        'file:/usr/local/lib/systemd/system/voctomix2-streaming-sink.service',
        'pkg_apt:ffmpeg'
    },
    'tags': {
        'causes-downtime',
    },
    'running': None, # get's auto-started by svc_systemd:voctomix2-voctocore
}

## streaming-sink
for pname, pdevice in node.metadata.get('voctocore/playout', {}).items():
    if pname not in PLAYOUT_PORTS:
        raise BundleError(f'{node.name} wants to use voctocore playout for {pname}, which does not exist. Valid choices: {",".join(sorted(PLAYOUT_PORTS))}')

    files[f'/opt/voctomix2/scripts/playout_{pname}.sh'] = {
        'source': 'decklink-playout.sh',
        'content_type': 'mako',
        'context': {
            'device': pdevice,
            'port': PLAYOUT_PORTS[pname],
        },
        'mode': '0755',
        'triggers': {
            f'svc_systemd:voctomix2-playout-{pname}:restart',
        },
    }
    files[f'/usr/local/lib/systemd/system/voctomix2-playout-{pname}.service'] = {
        'source': 'voctomix2-playout.service',
        'content_type': 'mako',
        'context': {
            'pname': pname,
        },
        'triggers': {
            'action:systemd-reload',
            f'svc_systemd:voctomix2-playout-{pname}:restart',
        },
    }
    svc_systemd[f'voctomix2-playout-{pname}'] = {
        'after': {
            'svc_systemd:voctomix2-voctocore',
        },
        'needs': {
            f'file:/opt/voctomix2/scripts/playout_{pname}.sh',
            f'file:/usr/local/lib/systemd/system/voctomix2-playout-{pname}.service',
            'pkg_apt:ffmpeg'
        },
        'tags': {
            'causes-downtime',
        },
    }

for pname in PLAYOUT_PORTS:
    if pname in node.metadata.get('voctocore/playout', {}):
        continue

    actions[f'voctocore_stop-playout_{pname}'] = {
        'command': f'systemctl disable --now voctomix2-playout-{pname}',
        'unless': f'! systemctl is-active voctomix2-playout-{pname}',
        'before': {
            'directory:/usr/local/lib/systemd/system',
        },
    }
