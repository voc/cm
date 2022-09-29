from json import loads
from os import environ
from os.path import join

import bwkeepass as keepass

defaults = {
    'users': {
        'root': {
            'home': '/root',
            'shell': '/bin/bash',
            'password': keepass.password(['Allgemein', 'Benutzerpasswörter', 'SSH Passwort und Key root']) if environ.get('BW_KEEPASS_PASSWORD') else None,
        },
    },
}

if node.os_version[0] > 9:
    defaults['apt'] = {
        'packages': {
            'kitty-terminfo': {},
        },
    }


@metadata_reactor.provides(
    'users',
)
def add_users_from_json(metadata):
    ign_default =  metadata.get('do_not_import_default_users', False)

    with open(join(repo.path, 'configs', 'users.json'), 'r') as f:
        json = loads(f.read())

    users = {}
    metadata_users = metadata.get('users', {})
    for uname, should_exist in json.items():
        if should_exist and not ign_default:
            users[uname] = {}
        elif uname not in metadata_users:
            users[uname] = {
                'delete': True,
            }

    return {
        'users': users,
    }


@metadata_reactor.provides(
    'users',
)
def user_keys_and_sudo(metadata):
    users = {}
    metadata_users = metadata.get('users', {})
    # First, add all admin users
    for uname, uconfig in metadata_users.items():
        if not uconfig.get('delete', False):
            users[uname] = {
                'sudo_commands': {'ALL'},
            }
            if uname not in ('root', 'voc'):
                users[uname]['ssh_pubkey'] = keepass.notes(['ansible', 'authorized_keys', uname])

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
                'password': keepass.password(['ansible', 'logins', 'voc']) if environ.get('BW_KEEPASS_PASSWORD') else None,
                'ssh_pubkey': repo.libs.faults.join_faults(pubkey, '\n'),
                'sudo_commands': {'ALL'},
            },
        },
    }
