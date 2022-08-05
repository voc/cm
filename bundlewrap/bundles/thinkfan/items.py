files['/usr/local/bin/thinkfan-configwriter'] = {
    'source': 'configwriter.py',
    'mode': '0755',
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
        'file:/usr/local/bin/thinkfan-configwriter',
        'pkg_apt:thinkfan',
    },
}
