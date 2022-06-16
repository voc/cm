if node.has_bundle('apt') and node.os_version[0] > 10:
    defaults = {
        'apt': {
            'packages': {
                'systemd-timesyncd': {
                    'needed_by': {
                        'action:systemd-enable-ntp',
                    },
                },
            },
        },
    }
