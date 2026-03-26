from bundlewrap.metadata import atomic

defaults = {
    'apt': {
        'packages': {
            'vsftpd': {},
        },
    },
    'vsftpd': {
        'users': {
        },
        'restrict-to': {
            "voc-internal",
            "voc-vpn",
        }
    },
}


@metadata_reactor.provides(
    'vsftpd/users',
)
def autogenerate_sony_camera_config(metadata):
    users = {}
    for cam in [1,2,3,4,5,6]:
        users[f'saal{cam}-sony'] = {
                'password': repo.vault.human_password_for(f'{node.name} sony {cam}', words=1),
                'localroot': f'/video/tmp/fossgis2026/sony/saal{cam}',
        }

    return {
        'vsftpd': {
            'users': users
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
