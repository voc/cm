from json import loads
from os import environ
from os.path import join

import bwkeepass as keepass

defaults = {
    'apt': {
        'packages': {
            'kitty-terminfo': {},
        },
    },
    'users': {
        'root': {
            'home': '/root',
            'shell': '/bin/bash',
            'password': keepass.password(['Allgemein', 'Benutzerpasswörter', 'SSH Passwort und Key root']) if environ.get('BW_KEEPASS_FILE') else None,
        },
    },
}


@metadata_reactor.provides(
    'users',
)
def add_users_from_json(metadata):
    with open(join(repo.path, 'configs', 'users.json'), 'r') as f:
        json = loads(f.read())

    users = {}
    metadata_users = metadata.get('users', {})
    # First, add all admin users
    for uname, should_exist in json.items():
        if should_exist:
            users[uname] = {
                'ssh_pubkey': keepass.notes(['ansible', 'authorized_keys', uname]),
                'sudo_commands': {'ALL'},
            }
        elif uname not in metadata_users:
            users[uname] = {
                'delete': True,
            }

    return {
        'users': users,
    }


@metadata_reactor.provides(
    'users/voc',
)
def user_voc(metadata):
    pubkey = []

    for user, attrs in sorted(metadata.get('users', {}).items()):
        if 'ssh_pubkey' in attrs:
            pubkey.extend([
                f'# {user}',
                attrs['ssh_pubkey'],
                '',
            ])

    return {
        'users': {
            'voc': {
                'password': keepass.password(['ansible', 'logins', 'voc']) if environ.get('BW_KEEPASS_FILE') else None,
                'ssh_pubkey': repo.libs.faults.join_faults(pubkey, '\n'),
                'sudo_commands': {'ALL'},
            },
        },
    }
