from bundlewrap.exceptions import BundleError
from os.path import exists, join

assert node.has_bundle('voctocore')

room_number = node.metadata.get('room_number', 0)
event_slug = node.metadata.get('event/slug')

directories['/opt/voc/share'] = {
    'purge': True,
}

files['/opt/voc/schedule_url'] = {
    'content': node.metadata.get('event/schedule_json', '') + '\n',
    'triggers': {
        'action:voctocore-artwork_update_schedule_and_overlays',
    },
}

files['/opt/voc/overlays_url'] = {
    'content': node.metadata.get('event/overlays', '') + '\n',
    'triggers': {
        'action:voctocore-artwork_update_schedule_and_overlays',
    },
}

files['/usr/local/bin/update-schedule-and-overlays'] = {
    'mode': '0755',
    'content_type': 'mako',
}

actions['voctocore-artwork_update_schedule_and_overlays'] = {
    'command': 'systemctl start update_schedule_and_overlays.service',
    'triggered': True,
    'needs': {
        'file:/opt/voc/overlays_url',
        'file:/opt/voc/schedule_url',
        'file:/usr/local/bin/update-schedule-and-overlays',
        'pkg_apt:curl',
        'pkg_apt:libxml2-utils',
        'svc_systemd:update_schedule_and_overlays.timer',
    },
}

for target_file, possible_sources in {
    '/opt/voc/share/overlay_hd.png': [
        join(event_slug, f'saal{room_number}', 'overlay_hd.png'),
        join(event_slug, 'overlay_hd.png'),
        'default-overlay-hd.png',
    ],
    '/opt/voc/share/overlay_slides.png': [
        join(event_slug, f'saal{room_number}', 'overlay_slides.png'),
        join(event_slug, 'overlay_slides.png'),
        'default-overlay-slides.png',
    ],
    '/opt/voc/share/bgloop.ts': [
        join(event_slug, f'saal{room_number}', 'bgloop.ts'),
        join(event_slug, 'bgloop.ts'),
        'default-bgloop.ts',
    ],
    '/opt/voc/share/bg.png': [
        join(event_slug, f'saal{room_number}', 'bg.png'),
        join(event_slug, 'bg.png'),
        'default-bg.png',
    ],
    '/opt/voc/share/bg_lec.png': [
        join(event_slug, f'saal{room_number}', 'bg_lec.png'),
        join(event_slug, 'bg_lec.png'),
        'default-bg_lec.png',
    ],
    '/opt/voc/share/bg_lecm.png': [
        join(event_slug, f'saal{room_number}', 'bg_lecm.png'),
        join(event_slug, 'bg_lecm.png'),
        'default-bg_lecm.png',
    ],
    '/opt/voc/share/bg_sbs.png': [
        join(event_slug, f'saal{room_number}', 'bg_sbs.png'),
        join(event_slug, 'bg_sbs.png'),
        'default-bg_sbs.png',
    ],
    '/opt/voc/share/pause.ts': [
        join(event_slug, f'saal{room_number}', 'pause.ts'),
        join(event_slug, 'pause.ts'),
        'default-pause.ts',
    ],
    '/opt/voc/share/nostream.ts': [
        join(event_slug, f'saal{room_number}', 'nostream.ts'),
        join(event_slug, 'nostream.ts'),
        'default-nostream.ts',
        join(event_slug, f'saal{room_number}', 'nostream.png'),
        join(event_slug, 'nostream.png'),
        'default-nostream.png',
    ],
    '/opt/voc/share/pause-music.mp3': [
        join(event_slug, f'saal{room_number}', 'pause-music.mp3'),
        join(event_slug, 'pause-music.mp3'),
        'default-pause-music.mp3',
    ],
}.items():
    source_file = None

    for source in possible_sources:
        if exists(join(repo.path, 'data', 'voctocore-artwork', 'files', source)):
            source_file = source
            break
    if source_file is not None:
        files[target_file] = {
            'source': source,
            'content_type': 'binary',
            'triggers': {
                'svc_systemd:voctomix2-voctocore:restart',
            },
        }
