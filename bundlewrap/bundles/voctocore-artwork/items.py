from bundlewrap.exceptions import BundleError
from os.path import exists, join

room_number = node.metadata.get('event/room_number', 0)
event_acronym = node.metadata.get('event/acronym')

directories['/opt/voc/share'] = {
    'purge': True,
}

for target_file, possible_sources in {
    '/opt/voc/share/overlay_hd.png': [
        join(event_acronym, f'saal{room_number}', 'overlay_hd.png'),
        join(event_acronym, 'overlay_hd.png'),
        'default-overlay-hd.png',
    ],
    '/opt/voc/share/overlay_slides.png': [
        join(event_acronym, f'saal{room_number}', 'overlay_slides.png'),
        join(event_acronym, 'overlay_slides.png'),
        'default-overlay-slides.png',
    ],
    '/opt/voc/share/bgloop.ts': [
        join(event_acronym, f'saal{room_number}', 'bgloop.ts'),
        join(event_acronym, 'bgloop.ts'),
        'default-bgloop.ts',
    ],
    '/opt/voc/share/bg.png': [
        join(event_acronym, f'saal{room_number}', 'bg.png'),
        join(event_acronym, 'bg.png'),
        'default-bg.png',
    ],
    '/opt/voc/share/pause.ts': [
        join(event_acronym, f'saal{room_number}', 'pause.ts'),
        join(event_acronym, 'pause.ts'),
        'default-pause.ts',
    ],
    '/opt/voc/share/nostream.ts': [
        join(event_acronym, f'saal{room_number}', 'nostream.ts'),
        join(event_acronym, 'nostream.ts'),
        'default-nostream.ts',
        join(event_acronym, f'saal{room_number}', 'nostream.png'),
        join(event_acronym, 'nostream.png'),
        'default-nostream.png',
    ],
    '/opt/voc/share/pause-music.mp3': [
        join(event_acronym, f'saal{room_number}', 'pause-music.mp3'),
        join(event_acronym, 'pause-music.mp3'),
        'default-pause-music.mp3',
    ],
}.items():
    source_file = None

    for source in possible_sources:
        if exists(join(repo.path, 'data', 'voctocore-artwork', 'files', source)):
            source_file = source
            break
    else:
        raise BundleError(f'{node.name}: could not find any suitable artwork files for {target_file}')

    files[target_file] = {
        'source': source,
        'content_type': 'binary',
    }
