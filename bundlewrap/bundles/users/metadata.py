from tomlkit import loads
from os import environ
from os.path import dirname, join

from bundlewrap.exceptions import BundleError

import bwkeepass as keepass

defaults = {
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
    defaults['apt'] = {
        'packages': {
            'kitty-terminfo': {},
        },
    }

with open(join(dirname(repo.path), 'users.toml'), 'r') as f:
    USERS_TOML = loads(f.read())


@metadata_reactor.provides(
    'users',
)
def add_users_from_toml(metadata):
    ign_default =  metadata.get('do_not_import_default_users', False)

    users = {
        uname: {}
        for uname, uconfig in metadata.get('users', {}).items()
        if not uconfig.get('delete', False)
    }

    # first, establish a list of all users that should exist on the
    # system
    for uname, uconfig in USERS_TOML.items():
        if uconfig['enable_event'] and not ign_default:
            users[uname] = {}

    # second, process all users so we have stuff like uids, ssh keys
    # and sudo
    for uname in users:
        if uname in ('root',):
            continue

        if metadata.get(f'users/{uname}/sudo_commands', None) is None:
            # we explicitely check for None here, so we can set
            # sudo_commands to an empty list to restrict users.
            users[uname]['sudo_commands'] = {'ALL'}

        uid = metadata.get(f'users/{uname}/uid', None)
        if uname in USERS_TOML:
            if uid is not None:
                raise BundleError(f'{node.name}: user {uname} tries to overwrite deterministic uid, which is not allowed.')

            users[uname]['uid'] = USERS_TOML[uname]['uid']

            if USERS_TOML[uname].get('ssh_pubkeys', set()):
                users[uname]['ssh_pubkeys'] = set(USERS_TOML[uname]['ssh_pubkeys'])
        elif uid is None:
            raise BundleError(f'{node.name}: user {uname} has no uid set, please set one manually')
        elif int(uid) < 2000:
            raise BundleError(f'{node.name}: user {uname} tries to use uid {uid}, but uids below 2000 are reserved for automatic provisioning')

    # last, loop through every user in USERS_TOML again and delete
    # every user that should not exist
    for uname in USERS_TOML:
        if uname not in users:
            users[uname] = {
                'delete': True,
            }

    return {
        'users': users,
    }


@metadata_reactor.provides(
    'users/voc/password',
    'users/voc/ssh_pubkeys',
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
            },
        },
    }
