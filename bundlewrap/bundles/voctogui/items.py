assert node.has_bundle('voctomix2')

files['/opt/voctomix2/voctogui-config.ini'] = {
    'content_type': 'mako',
    'context': {
        'high_dpi': node.metadata.get('voctogui/high_dpi'),
        'play_audio': node.metadata.get('voctogui/play_audio'),
        'room_number': node.metadata.get('event/room_number'),
        'video_display': node.metadata.get('voctogui/video_display'),
    },
    'triggers': {
        'svc_systemd:voctomix2-voctogui:restart',
    }
}

files['/usr/local/lib/systemd/system/voctomix2-voctogui.service'] = {
    'content_type': 'mako',
    'context': {
        'high_dpi': node.metadata.get('voctogui/high_dpi'),
    },
    'triggers': {
        'action:systemd-reload',
    },
}

files['/usr/local/bin/voctogui-check-connection.sh'] = {
    'content_type': 'mako',
    'context': {
        'room_number': node.metadata.get('event/room_number'),
    },
    'source' : 'voctogui-check-connection.sh',
    'mode': 755,
    'triggers': {
        'svc_systemd:voctomix2-voctogui:restart',
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
