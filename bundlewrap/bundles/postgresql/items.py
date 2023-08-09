postgresql_version = int(node.metadata.get('postgresql/version'))

pkg_apt = {
    'postgresql-common': {},
    'postgresql-client-common': {},
    'postgresql-{}'.format(postgresql_version): {},
    'postgresql-client-{}'.format(postgresql_version): {},
    'postgresql-server-dev-{}'.format(postgresql_version): {}
}

if node.has_bundle('zfs'):
    for pkgname, pkgconfig in pkg_apt.items():
        pkg_apt[pkgname]['needs'] = {
            'zfs_dataset:tank/postgresql',
        }


directories = {
    '/etc/postgresql': {
        'owner': None,
        'group': None,
        'mode': None,
        # Keeping old configs messes with cluster-auto-detection.
        'purge': True,
    },
    # This is needed so the above purge does not remove the version
    # currently installed.
    '/etc/postgresql/{}/main'.format(postgresql_version): {
        'owner': 'postgres',
        'group': 'postgres',
        'mode': '0755',
        'needs': {f'pkg_apt:{i}' for i in pkg_apt.keys()},
    },
}

files = {
    "/etc/postgresql/{}/main/pg_hba.conf".format(postgresql_version): {
        'content_type': 'mako',
        'owner': 'postgres',
        'group': 'postgres',
        'triggers': {
            'svc_systemd:postgresql:restart',
        },
    },
    "/etc/postgresql/{}/main/postgresql.conf".format(postgresql_version): {
        'content_type': 'mako',
        'context': node.metadata.get('postgresql'),
        'owner': 'postgres',
        'group': 'postgres',
        'after': {
            # postgresql won't start if the configured locale isn't available
            'action:locale-gen',
        },
        'triggers': {
            'svc_systemd:postgresql:restart',
        },
    },
}

postgres_roles = {
    'root': {
        'password': repo.vault.password_for('{} postgresql root'.format(node.name)),
        'superuser': True,
        'needs': {
            'svc_systemd:postgresql',
        },
    },
}

svc_systemd = {
    'postgresql': {
        'after': {
            'pkg_apt:',
        },
        'triggers': {
            'action:postgresql_wait_after_restart',
        },
    },
}

actions = {
    'postgresql_wait_after_restart': {
        # postgresql doesn't accept connections immediately after restarting
        'command': 'sleep 10',
        'triggered': True,
        'before': {
            'postgres_role:',
            'postgres_db:',
        },
    },
}

for user, config in node.metadata.get('postgresql/roles', {}).items():
    postgres_roles[user] = {
        'password': config['password'],
        'needs': {
            'svc_systemd:postgresql',
        },
    }

for database, config in node.metadata.get('postgresql/databases', {}).items():
    postgres_dbs[database] = config
