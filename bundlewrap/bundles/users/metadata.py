from tomlkit import loads
from os import environ
from os.path import dirname, join

import bwkeepass as keepass

defaults = {
    'apt': {
        'packages': {
            'vim': {},
        },
    },
    'users': {
        'root': {
            'home': '/root',
            'shell': '/bin/bash',
            'password': keepass.password(['Allgemein', 'Benutzerpasswörter', 'SSH Passwort und Key root']) if environ.get('BW_KEEPASS_PASSWORD') else None,
        },
        'voc': {},
    },
}

if node.os_version[0] > 9:
    defaults['apt']['packages']['kitty-terminfo'] = {}


@metadata_reactor.provides(
    'users',
)
def add_users_from_json(metadata):
    ign_default =  metadata.get('do_not_import_default_users', False)

    with open(join(dirname(repo.path), 'users.toml'), 'r') as f:
        users_toml = loads(f.read())

    users = {}
    metadata_users = metadata.get('users', {})
    for uname, uconfig in users_toml.items():
        should_exist = uconfig['enable']

        if should_exist and not ign_default:
            users[uname] = {
                'uid': uconfig['uid'],
                'ssh_pubkeys': set(uconfig.get('ssh_pubkeys', set())),
            }
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
def user_sudo(metadata):
    users = {}
    metadata_users = metadata.get('users', {})
    # every user in metadata should be able to use sudo
    for uname, uconfig in metadata_users.items():
        if not uconfig.get('delete', False) and 'sudo_commands' not in uconfig:
            users[uname] = {
                'sudo_commands': {'ALL'},
            }

    return {
        'users': users,
    }


@metadata_reactor.provides(
    'users/voc',
)
def user_voc(metadata):
    pubkey = set()

    for user, attrs in sorted(metadata.get('users', {}).items()):
        pubkey |= set(attrs.get('ssh_pubkeys', set()))

    return {
        'users': {
            'voc': {
                'password': keepass.password(['ansible', 'logins', 'voc']) if environ.get('BW_KEEPASS_PASSWORD') else None,
                'ssh_pubkeys': pubkey,
                'sudo_commands': {'ALL'},
            },
        },
    }
