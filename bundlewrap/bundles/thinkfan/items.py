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

svc_systemd['thinkfan'] = {
    'needs': {
        'file:/etc/thinkfan.conf',
        'pkg_apt:thinkfan',
    },
}
