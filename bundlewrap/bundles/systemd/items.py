timezone = node.metadata.get('timezone', 'Europe/Berlin')

actions = {
    'systemd-reload': {
        'command': 'systemctl daemon-reload',
        'cascade_skip': False,
        'triggered': True,
        'needed_by': {
            'svc_systemd:',
        },
    },
    'systemd-hostname': {
        'command': 'hostnamectl set-hostname {}'.format(node.metadata['hostname']),
        'unless': '[ "$(hostnamectl --static)" = "{}" ]'.format(node.metadata['hostname']),
        # Provided by bundle:basic
        'needs': {
            'file:/etc/hosts',
        },
    },
    'systemd-timezone': {
        'command': 'timedatectl set-timezone {}'.format(timezone),
        'unless': 'timedatectl status | grep -Fi \'time zone\' | grep -i \'{}\''.format(timezone.lower()),
    },
    'systemd-enable-ntp': {
        'command': 'timedatectl set-ntp true',
        'unless': 'timedatectl status | grep -Fi \'ntp service\' | grep -i \'active\'',
    },
}

files = {
    '/etc/systemd/journald.conf': {
        'content_type': 'mako',
        'context': {
            'journal': node.metadata.get('systemd/journal', {}),
        },
        'triggers': {
            'svc_systemd:systemd-journald:restart',
        },
    },
}

directories = {
    '/usr/local/lib/systemd/system': {
        'purge': True,
        'triggers': {
            'action:systemd-reload',
        },
    },
}

svc_systemd = {
    'systemd-journald': {
        'needs': {
            'file:/etc/systemd/journald.conf',
        },
    },
}

if node.metadata.get('systemd/ignore_power_switch', False):
    files['/etc/systemd/logind.conf'] = {
        'source': 'logind-ignore.conf',
        'comment': 'when changing this file, a reboot is needed to apply the changes',
    }
else:
    files['/etc/systemd/logind.conf'] = {
        'source': 'logind-poweroff.conf',
        'comment': 'when changing this file, a reboot is needed to apply the changes',
    }
