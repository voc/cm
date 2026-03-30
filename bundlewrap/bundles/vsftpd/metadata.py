from bundlewrap.metadata import atomic

defaults = {
    'apt': {
        'packages': {
            'vsftpd': {},
        },
    },
    'vsftpd': {
        'users': {},
    },
    'zfs': {
        'datasets': {
            'video/vsftpd': {
                'mountpoint': '/srv/vsftpd',
            },
        },
    },
}


@metadata_reactor.provides(
    'vsftpd/users',
)
def autogenerate_some_user_config(metadata):
    users = {}
    datasets = {}
    for user in metadata.get('vsftpd/users', {}):
        users[user] = {
            'password': repo.vault.human_password_for(f'{node.name} vsftpd user {user}', words=1),
            'localroot': f'/srv/vsftpd/{user}',
        }

    return {
        'vsftpd': {
            'users': users
        }
    }


@metadata_reactor.provides(
    'zfs/datasets',
)
def zfs(metadata):
    users = {}
    datasets = {}
    for user in metadata.get('vsftpd/users', {}):
        datasets[f'video/vsftpd/{user}'] = {
            'mountpoint': metdata.get(('vsftpd', 'users', user, 'localroot')),
        }

    return {
        'zfs': {
            'datasets': datasets
        }
    }


@metadata_reactor.provides(
    'firewall/port_rules',
)
def firewall(metadata):
    return {
        'firewall': {
            'port_rules': {
                '20/tcp': atomic(metadata.get('vsftpd/restrict-to', set())),
                '21/tcp': atomic(metadata.get('vsftpd/restrict-to', set())),
            },
        },
    }
