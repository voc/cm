assert node.has_bundle('voctomix2')

files['/opt/voctomix2/voctogui-config.ini'] = {
    'content_type': 'mako',
    'context': {
        'highdpi': node.metadata.get('voctogui/highdpi'),
        'play_audio': node.metadata.get('voctogui/play_audio'),
        'room_number': node.metadata.get('event/room_number'),
        'video_display': node.metadata.get('voctogui/video_display'),
    },
}

files['/usr/local/lib/systemd/system/voctomix2-voctogui.service'] = {
    'triggers': {
        'action:systemd-reload',
    },
}

svc_systemd['voctomix2-voctogui'] = {
    'needs': {
        'file:/opt/voctomix2/voctogui-config.ini',
        'file:/usr/local/lib/systemd/system/voctomix2-voctogui.service',
        'git_deploy:/opt/voctomix2/release',
        'pkg_apt:'
    },
    'tags': {
        'causes-downtime',
    },
}
