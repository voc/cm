files = {
    '/usr/local/sbin/apply-sysctl': {
        'content':
            '#!/bin/sh\n'
            '\n'
            'cat /etc/sysctl.d/*.conf | sysctl -e -p -',
        'mode': '0700',
    },
    '/etc/sysctl.d/98-sysctl.conf': {
        'content_type': 'mako',
        'triggers': {
            'action:apply-sysctl-settings',
        },
    },
    '/etc/sysctl.conf': {
        'delete': True,
        'triggers': {
            'action:apply-sysctl-settings',
        },
    },
}

directories = {
    '/etc/sysctl.d': {
        'purge': True,
        'triggers': {
            'action:apply-sysctl-settings',
        },
    },
}

actions = {
    'apply-sysctl-settings': {
        'command': '/usr/local/sbin/apply-sysctl',
        'triggered': True,
        'needs': {
            'file:/usr/local/sbin/apply-sysctl',
        },
        'triggers': node.metadata.get('sysctl/reload_triggers', set())
    },
}
