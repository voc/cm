defaults = {
    'apt': {
        'packages': {
            'decklink-debugger': {},
            'desktopvideo': {},
            'fbset': {},
            'gir1.2-gst-plugins-base-1.0': {},
            'gir1.2-gstreamer-1.0': {},
            'gstreamer1.0-libav': {},
            'gstreamer1.0-plugins-bad': {},
            'gstreamer1.0-plugins-base': {},
            'gstreamer1.0-plugins-good': {},
            'gstreamer1.0-plugins-ugly': {},
            'gstreamer1.0-tools': {},
            'gstreamer1.0-vaapi': {},
            'i965-va-driver-shaders': {},
            'libgstreamer1.0-0': {},
            'python3': {},
            'python3-gi': {},
            'python3-pyinotify': {},
            'python3-scipy': {},
            'python3-sdnotify': {},
            'rlwrap': {},
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
