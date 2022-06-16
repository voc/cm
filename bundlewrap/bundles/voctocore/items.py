#'/usr/local/lib/systemd/system': {

event = node.metadata.get('event/acronym', '')
assert node.has_bundle('encoder-common')

### voc2mix
directories['/opt/voctomix2/release'] = {}
git_deploy['/opt/voctomix2/release'] = {
    'repo': 'https://c3voc.de/git/voctomix',
    'rev': 'voctomix2',
}
files['/opt/voctomix2/voctocore-config.ini'] = {
    'content_type': 'mako',
    'context': {
        'audio': node.metadata.get('voctocore/audio', {}),
        'backgrounds': node.metadata.get('voctocore/backgrounds', {}),
        'event': event,
        'mirror_view': node.metadata.get('voctocore/mirror_view'),
        'room_fahrplan_name': node.metadata.get('event/room_fahrplan_name', ''),
        'sources': node.metadata.get('voctocore/sources', {}),
        'static_background_image': node.metadata.get('voctocore/static_background_image'),
        'vaapi_enabled': node.metadata.get('voctocore/vaapi'),
    },
}
files['/usr/local/lib/systemd/system/voctomix2-voctocore.service'] = {
    'triggers': {
        'action:systemd-reload',
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
}


### Monitoring
files['/usr/local/sbin/check_system.d/check_recording.pl'] = {
    # will get executed automatically by bundle:mqtt-monitoring
    'mode': '0755',
}


### Additional scripts
directories['/opt/voctomix2/scripts'] = {
    'purge': True,
}
# TODO recording
# TODO streaming
