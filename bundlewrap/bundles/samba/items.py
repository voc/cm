svc_systemd = {
    'nmbd': {
        'needs': {
            'pkg_apt:samba',
        },
    },
    'smbd': {
        'needs': {
            'pkg_apt:samba',
        },
    },
}

files = {
    '/etc/samba/smb.conf': {
        'content_type': 'mako',
        'triggers': {
            'svc_systemd:nmbd:restart',
            'svc_systemd:smbd:restart',
        },
    },
    '/etc/systemd/system/nmbd.service.d/bundlewrap.conf': {
        'source': 'override.conf',
        'triggers': {
            'action:systemd-reload',
            'svc_systemd:nmbd:restart',
        },
    },
    '/etc/systemd/system/smbd.service.d/bundlewrap.conf': {
        'source': 'override.conf',
        'triggers': {
            'action:systemd-reload',
            'svc_systemd:smbd:restart',
        },
    },
}

last_action = set()
for user, uconfig in node.metadata.get('users', {}).items():
    if (
        'password' not in uconfig
        or uconfig.get('delete')
        or user in ('root',)
    ):
        continue

    actions[f'smbpasswd_for_user_{user}'] = {
        'command': f'smbpasswd -a -s {user}',
        'unless': f'pdbedit -L | grep -E "^{user}:"',
        'data_stdin': uconfig['password'] + '\n' + uconfig['password'],
        'needs': {
            'pkg_apt:samba',
            f'user:{user}',
        },
        'after': last_action,
    }
    last_action = {
        f'action:smbpasswd_for_user_{user}',
    }
