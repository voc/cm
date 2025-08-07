from bundlewrap.metadata import atomic

defaults = {
    'apt': {
        'packages': {
            'decklink-debugger': {},
            'desktopvideo': {},
            'desktopvideo-gui': {},
            'fbset': {},
            'gstreamer1.0-libav': {},
            'xauth': {}, # for x11 forwarding
            'mesa-va-drivers': {}, # contains amd drivers for vaapi
        },
    },
    'extra-commands-on-login': {
        '''echo "Free space in /video: $(df -h --output=avail /video | tail -n1 | sed 's/ //g')"'''
    },
    'unit-status-on-login': {
        'voctomix2-voctocore',
        'voctomix2-streaming-sink',
        'voctomix2-recording-sink',
    },
    'users': {
        'voc': {
            'groups': {
                'audio', # playout
                'render', # vaapi
                'video', # playout
            },
        },
    },
    'voctocore': {
        'enable_sbs_presets_for_multi_camera': True,
        'mirror_view': False, # automatically mirrors SBS/LEC views
        'parallel_slide_recording': True,
        'parallel_slide_streaming': True,
        'programout_audiosink': 'autoaudiosink',
        'programout_enabled': False,
        'programout_videosink': 'autovideosink',
        'srt_publish': True,
        'streaming_use_dynaudnorm': False,
        'translators_premixed': False,
        'vaapi': False,
        'fps': 25,
    },
    'voctomix2': {
        'deploy_triggers': {
            'svc_systemd:voctomix2-voctocore:restart',
        },
    },
}

if not node.has_bundle('zfs'):
    defaults['mqtt-monitoring'] = {
        'plugins_daily': {
            'disk_space_usage',
        },
    }


@metadata_reactor.provides(
    'voctocore/streaming_endpoint',
)
def streaming_endpoint(metadata):
    return {
        'voctocore': {
            'streaming_endpoint': 's{}'.format(metadata.get('room_number')),
        },
    }


@metadata_reactor.provides(
    'voctocore/sources',
)
def auto_audio_level(metadata):
    sources = {}
    for aname, aconfig in metadata.get('voctocore/audio', {}).items():
        sources[aconfig['input']] = {
            'volume': aconfig.get('volume', '1.0'),
        }

    return {
        'voctocore': {
            'sources': sources,
        },
    }


@metadata_reactor.provides(
    'firewall/port_rules',
)
def firewall(metadata):
    port_rules = {}

    for port in (
        9998,
        9999,
        11000, # mix recording
        11100, # mix preview
        12000,
        14000,
        15000, # mix live
        15100, # mix preview live
        16000, # background video
        17000, # video blinder
        18000, # audio blinder
    ):
        port_rules[f'{port}/tcp'] = atomic(metadata.get('voctocore/restrict-to', set()))


    for idx, source in enumerate(metadata.get('voctocore/sources', {})):
        for port in (
            10000, # source input
            13000, # source recording
            13100, # source preview
            15001, # source live
        ):
            port_rules[f'{port+idx}/tcp'] = atomic(metadata.get('voctocore/restrict-to', set()))


    return {
        'firewall': {
            'port_rules': port_rules,
        },
    }
