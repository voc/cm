users_from_metadata = set()
additional_users = node.metadata.get('openssh/allowed_users', set())

for user, config in node.metadata.get('users', {}).items():
    if 'ssh_pubkey' in config and not config.get('delete', False):
        users_from_metadata.add(user)

login_users = users_from_metadata.union(additional_users)

files = {
    '/etc/ssh/sshd_config': {
        'content_type': 'mako',
        'context': {
            'login_users': login_users,
            'admin_users': users_from_metadata,
            'enable_x_forwarding_for_admins': node.metadata.get('openssh/enable_x_forwarding_for_admins', False),
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
    service: {
        'needs': {
            'file:/etc/systemd/system/ssh.service.d/bundlewrap.conf',
            'file:/etc/ssh/sshd_config',
            'pkg_apt:openssh-server',
        },
    },
}
