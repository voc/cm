defaults = {
    'apt': {
        'packages': {
            'decklink-debugger': {},
            'desktopvideo': {},
            'fbset': {},
            'gstreamer1.0-libav': {},
        },
    },
    'voctocore': {
        'mirror_view': False, # automatically mirrors SBS/LEC views
        'parallel_slide_recording': True,
        'parallel_slide_streaming': True,
        'static_background_image': True,
        'vaapi': False,
        'srt_publish': False,
        'backgrounds': {
            'lec': {
                'kind': 'img',
                'path': '/opt/voc/share/bg_lec.png',
                'composites': 'lec',
            },
            'lecm': {
                'kind': 'img',
                'path': '/opt/voc/share/bg_lecm.png',
                'composites': '|lec',
            },
            'sbs': {
                'kind': 'img',
                'path': '/opt/voc/share/bg_sbs.png',
                'composites': 'sbs',
            },
            'fs': {
                'kind': 'test',
                'pattern': 'black',
                'composites': 'fs',
            },
        },
    },
}

@metadata_reactor.provides(
    'voctocore/sources',
)
def auto_audio_level(metadata):
    sources = {}
    for aname, aconfig in metadata.get('voctocore/audio', {}).items():
        sources[aconfig['input']] = {
            'volume': '1.0',
        }

    return {
        'voctocore': {
            'sources': sources,
        },
    }
