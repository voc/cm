users_from_metadata = set()
additional_users = node.metadata.get('openssh/allowed_users', set())

for user, config in node.metadata.get('users', {}).items():
    if 'ssh_pubkeys' in config and not config.get('delete', False):
        users_from_metadata.add(user)

login_users = users_from_metadata.union(additional_users)

files = {
    '/etc/ssh/sshd_config': {
        'content_type': 'mako',
        'context': {
            'login_users': login_users,
            'admin_users': users_from_metadata,
            'allow_password_auth_for_addresses': node.metadata.get('openssh/allow_password_auth_for_addresses', ['10.73.0.0/16']),
        },
        'triggers': {
            'action:sshd_check_config',
        },
    },
    '/etc/systemd/system/ssh.service.d/bundlewrap.conf': {
        'source': 'override.conf',
        'triggers': {
            'action:sshd_check_config',
        },
    },
}

actions = {
    'sshd_check_config': {
        'command': 'sshd -T -C user=root -C host=localhost -C addr=localhost',
        'triggered': True,
        'triggers': {
            'svc_systemd:ssh:restart',
        },
    },
}

svc_systemd = {
    'ssh': {
        'needs': {
            'file:/etc/systemd/system/ssh.service.d/bundlewrap.conf',
            'file:/etc/ssh/sshd_config',
            'pkg_apt:openssh-server',
        },
    },
}
