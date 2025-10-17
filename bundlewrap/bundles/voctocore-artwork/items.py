from bundlewrap.exceptions import BundleError
from os.path import exists, join


def backgrounds(event_slug, room_number, which, fallback=None):
    options = [
        join(event_slug, f'saal{room_number}', f'bg_{which}.png'),
        join(event_slug, f'bg_{which}.png'),
    ]

    if fallback:
        options.extend([
            join(event_slug, f'saal{room_number}', f'bg_{fallback}.png'),
            join(event_slug, f'bg_{fallback}.png'),
        ])

    options.extend([
        join(event_slug, f'saal{room_number}', 'bg.png'),
        join(event_slug, 'bg.png'),
        'default-bg.png',
    ])

    return {
        f'/opt/voc/share/bg_{which}.png': options,
    }


directories['/opt/voc/share'] = {
    'purge': True,
}

files['/opt/voc/schedule_url'] = {
    'content': node.metadata.get('event/schedule_json', '') + '\n',
    'content_type': 'text',
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

if node.has_bundle('voctocore'):
    room_number = node.metadata.get('room_number', 0)
    event_slug = node.metadata.get('event/slug')

    for target_file, possible_sources in {
        '/opt/voc/share/pause.ts': [
            join(event_slug, f'saal{room_number}', 'pause.ts'),
            join(event_slug, 'pause.ts'),
            'default-pause.ts',
        ],
        '/opt/voc/share/pause-music.mp3': [
            join(event_slug, f'saal{room_number}', 'pause-music.mp3'),
            join(event_slug, 'pause-music.mp3'),
            'default-pause-music.mp3',
        ],
        **backgrounds(event_slug, room_number, 'lec'),
        **backgrounds(event_slug, room_number, 'lecm'),
        **backgrounds(event_slug, room_number, 'sbs', 'lec'),
        **backgrounds(event_slug, room_number, 'sbsm', 'lecm'),
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
                "tags": {
                    "causes-downtime",
                },
                'triggers': {
                    'svc_systemd:voctomix2-voctocore:restart',
                },
            }

    files['/opt/voc/overlays_url'] = {
        'content': node.metadata.get('event/overlays', '') + '\n',
        'content_type': 'text',
        'triggers': {
            'action:voctocore-artwork_update_schedule_and_overlays',
        },
    }
else:
    # required by the updater script, but we only need overlays if we have voctocore
    files['/opt/voc/overlays_url'] = {
        'content': '\n',
        'content_type': 'text',
    }
