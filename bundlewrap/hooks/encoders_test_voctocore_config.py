from re import match

from bundlewrap.exceptions import BundleError

# last checked 2022-06-16
# <https://gstreamer.freedesktop.org/documentation/decklink/decklinkvideosrc.html?gi-language=c#GstDecklinkModes>
GSTREAMER_SUPPORTED_FORMATS = {
    'ntsc',
    'ntsc2398',
    'pal',
    'ntsc-p',
    'pal-p',
    '1080p2398',
    '1080p24',
    '1080p25',
    '1080p2997',
    '1080p30',
    '1080i50',
    '1080i5994',
    '1080i60',
    '1080p50',
    '1080p5994',
    '1080p60',
    '720p50',
    '720p5994',
    '720p60',
    '1556p2398',
    '1556p24',
    '1556p25',
    '2kdcip2398',
    '2kdcip24',
    '2kdcip25',
    '2kdcip2997',
    '2kdcip30',
    '2kdcip50',
    '2kdcip5994',
    '2kdcip60',
    '2160p2398',
    '2160p24',
    '2160p25',
    '2160p2997',
    '2160p30',
    '2160p50',
    '2160p5994',
    '2160p60',
    'ntsc-widescreen',
    'ntsc2398-widescreen',
    'pal-widescreen',
    'ntsc-p-widescreen',
    'pal-p-widescreen',
    '4kdcip2398',
    '4kdcip24',
    '4kdcip25',
    '4kdcip2997',
    '4kdcip30',
    '4kdcip50',
    '4kdcip5994',
    '4kdcip60',
    '8kp2398',
    '8kp24',
    '8kp25',
    '8kp2997',
    '8kp30',
    '8kp50',
    '8kp5994',
    '8kp60',
    '8kdcip2398',
    '8kdcip24',
    '8kdcip25',
    '8kdcip2997',
    '8kdcip30',
    '8kdcip50',
    '8kdcip5994',
    '8kdcip60',
}


def test_node(repo, node, **kwargs):
    run_test(node)


def node_apply_start(repo, node, interactive=False, **kwargs):
    run_test(node)


def run_test(node):
    used_devices = {}

    for sname, sconfig in node.metadata.get('voctocore/sources', {}).items():
        if sconfig.get('kind', 'decklink') != 'decklink':
            continue

        if not sname == 'slides' and not match(r'^cam[0-9]+$', sname):
            raise BundleError(f'{node.name}: voctocore source {sname} has invalid name, must be either "slides" or match "cam[0-9]+"')

        device = str(sconfig.get('devicenumber'))
        if not device.isdigit():
            raise BundleError(f'{node.name}: voctocore source {sname} has invalid device number {device}')
        elif device in used_devices:
            raise BundleError(f'{node.name}: voctocore source {sname} device already used by {used_devices[device]}')
        used_devices[device] = f'source {sname}'

        if sconfig['mode'] not in GSTREAMER_SUPPORTED_FORMATS:
            raise BundleError(f'{node.name}: voctocore source {sname} wants input format {sconfig["mode"]}, which isn\'t supported by gstreamer')

    used_audio = {}
    for aname, aconfig in node.metadata.get('voctocore/audio', {}).items():
        if aconfig['input'] not in node.metadata.get('voctocore/sources', {}):
            raise BundleError(f'{node.name}: voctocore audio {aname} wants input {aconfig["input"]}, which doesn\'t exist')

        if not match(r'^\d+\+\d+$', aconfig['streams']):
            if aconfig['streams'].isdigit():
                raise BundleError(f'{node.name}: voctocore audio {aname} is not in required format "{aconfig["streams"]}+{aconfig["streams"]}".')
            raise BundleError(f'{node.name}: voctocore audio {aname} is not in required format "X+X" (X being a SDI stream number).')

        for stream in aconfig['streams'].split('+'):
            audio_name = f'{aconfig["input"]} {stream}'
            if audio_name in used_audio:
                raise BundleError(f'{node.name}: voctocore audio {aname} wants input {audio_name}, which is already used by {used_audio[audio_name]}')

        for stream in aconfig['streams'].split('+'):
            used_audio[f'{aconfig["input"]} {stream}'] = aname

    for pname, pdevice in node.metadata.get('voctocore/playout', {}).items():
        device = str(pdevice)
        if not (device.isdigit() or device == 'fb'):
            raise BundleError(f'{node.name}: voctocore playout {pname} has invalid device number {device}')
        elif device in used_devices:
            raise BundleError(f'{node.name}: voctocore playout {pname} device already used by {used_devices[device]}')
        used_devices[device] = f'playout {sname}'
