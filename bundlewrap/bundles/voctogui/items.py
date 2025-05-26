voctomix_version = node.metadata.get("voctomix2/rev")
assert node.has_bundle('voctomix2')

encoder_ip = node.metadata.get('voctogui/encoder-ip', '10.73.{}.3'.format(node.metadata.get('room_number', 0)))

files['/opt/voctomix2/voctogui-config.ini'] = {
    'content_type': 'mako',
    "source": f"voctogui-config-by-version/{voctomix_version}.ini",
    'context': {
        'encoder_ip': encoder_ip,
        'high_dpi': node.metadata.get('voctogui/high_dpi'),
        'play_audio': node.metadata.get('voctogui/play_audio'),
        'vaapi': node.metadata.get('voctogui/vaapi'),
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
        'svc_systemd:voctomix2-voctogui:restart',
    },
}

files['/usr/local/bin/voctogui-check-connection.sh'] = {
    'content_type': 'mako',
    'context': {
        'encoder_ip': encoder_ip,
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
