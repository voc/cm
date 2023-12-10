files = {
    '/etc/crontab': {
        'content_type': 'mako',
        'context': {
            'min': (node.magic_number%60),
        },
    },
}

directories = {
    '/etc/cron.d': {
        'purge': True,
        'after': {
            'pkg_apt:',
        },
    },
}

svc_systemd = {
    'cron': {
        'needs': {
            'pkg_apt:cron',
        },
    },
}

for crontab, content in node.metadata.get('cron/jobs', {}).items():
    files['/etc/cron.d/{}'.format(crontab)] = {
        'source': 'cron_template',
        'content_type': 'mako',
        'context': {
            'cron': content,
        }
    }
