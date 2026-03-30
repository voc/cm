files['/etc/vsftpd.conf'] = {
    'triggers': {
        'svc_systemd:vsftpd:restart',
    },
}

files['/etc/pam.d/vsftpd_virtual'] = {
    'triggers': {
        'svc_systemd:vsftpd:restart',
    },
}

files['/etc/vsftpd/ftpd.passwd'] = {
    'content_type': 'mako',
    'context': {
        'users': node.metadata.get('vsftpd/users'),
    },
    'triggers': {
        'svc_systemd:vsftpd:restart',
    },
}

svc_systemd['vsftpd'] = {
    'needs': {
        'pkg_apt:vsftpd',
    },
}

for user in node.metadata.get('vsftpd/users'):
    localroot = node.metadata.get(('vsftpd', 'users', user, 'localroot'))
    password =  node.metadata.get(('vsftpd', 'users', user, 'password'))

    directories[localroot] = {
        'owner': 'voc',
        'group': 'voc',
        'needs': {
            f'zfs_dataset:video/vsftpd/{user}',
        },
    }

    files[f'/etc/vsftpd_user_conf/{user}'] = {
        'content': f"local_root={localroot}/",
        'triggers': {
            'svc_systemd:vsftpd:restart',
        },
    }
