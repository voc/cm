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

@metadata_reactor.provides(
    'voctomix2/rev',
)
def voctomix_version(metadata):
    if node.in_group('debian-bookworm'):
        return {
            'voctomix2': {
                'rev': '2.0',
            },
        }
    else: 
        return {
            'voctomix2': {
                'rev': 'voctomix2',
            },
        }
