files['/etc/thinkfan.conf'] = {
    'content_type': 'mako',
    'context': {
        'hwmon': node.metadata.get('thinkfan/hwmon', []),
    },
    'triggers': {
        'svc_systemd:thinkfan:restart',
    },
}

files['/etc/modprobe.d/thinkfan.conf'] = {
    'content': 'options thinkpad_acpi fan_control=1\n',
}

files['/etc/systemd/system/thinkfan.service.d/bundlewrap.conf'] = {
    'source': 'override.conf',
    'triggers': {
        'action:systemd-reload',
        'svc_systemd:thinkfan:restart',
    },
}

svc_systemd['thinkfan'] = {
    'needs': {
        'file:/etc/thinkfan.conf',
        'pkg_apt:thinkfan',
    },
}

files[f'/usr/local/sbin/check_system.d/fan_speed.sh'] = {
    'source': 'fan_speed.sh',
    'content_type': 'mako',
    'mode': '0755',
}
