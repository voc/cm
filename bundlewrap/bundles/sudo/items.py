groups = {
    'sudo': {},
}

directories = {
    '/etc/sudoers.d': {
        'purge': True,
        'after': {
            'pkg_apt:',
        },
    },
}

files = {
    '/etc/sudoers': {
        'mode': '0440',
        'needs': {
            'file:/etc/sudoers.d/bwusers',
        },
    },
    '/etc/sudoers.d/bwusers': {
        'content_type': 'mako',
    },
}

for filename, content in node.metadata.get('sudo/extra_configs', {}).items():
    files[f'/etc/sudoers.d/{filename}'] = {
        'content': '\n'.join(sorted(content)) + '\n',
        'mode': '0440',
    }
