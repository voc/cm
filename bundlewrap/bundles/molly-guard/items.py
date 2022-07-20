directories = {
    '/etc/molly-guard/messages.d': {
        'purge': True,
        'after': {
            'pkg_apt:molly-guard',
        },
    },
    '/etc/molly-guard/run.d': {
        'purge': True,
        'after': {
            'pkg_apt:molly-guard',
        },
    },
}

files = {
    '/etc/molly-guard/rc': {},

    '/etc/molly-guard/run.d/30-query-hostname': {
        'content_type': 'mako',
        'mode': '0755',
    },
}
