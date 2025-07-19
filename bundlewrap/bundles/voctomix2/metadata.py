DEBIAN_TO_VOCTOMIX_VERSION = {
    10: 'voctomix2',
    12: '2.2',
}

if node.has_any_bundle(['voctocore', 'voctogui']):
    defaults = {
        'apt': {
            'packages': {
                'gir1.2-gst-plugins-base-1.0': {},
                'gir1.2-gstreamer-1.0': {},
                'gstreamer1.0-plugins-bad': {},
                'gstreamer1.0-plugins-base': {},
                'gstreamer1.0-plugins-good': {},
                'gstreamer1.0-plugins-ugly': {},
                'gstreamer1.0-tools': {},
                'gstreamer1.0-vaapi': {},
                'gstreamer1.0-x': {},
                'libgstreamer1.0-0': {},
                'python3-gi': {},
                'python3-pyinotify': {},
                'python3-scipy': {},
                'python3-sdnotify': {},
                'rlwrap': {},
            },
        },
    }


if node.os_version[0] in DEBIAN_TO_VOCTOMIX_VERSION:
    defaults['voctomix2'] = {
        'rev': DEBIAN_TO_VOCTOMIX_VERSION[node.os_version[0]],
    }


@metadata_reactor.provides(
    'voctomix2/version_tuple',
)
def voctomix_version(metadata):
    rev = metadata.get('voctomix2/rev')

    if '.' in rev:
        version = tuple([int(i) for i in rev.split('.')])
    elif rev == 'voctomix2':
        version = (2,)
    else:
        version = (2, 9999)

    return {
        'voctomix2': {
            'version_tuple': version,
        },
    }
