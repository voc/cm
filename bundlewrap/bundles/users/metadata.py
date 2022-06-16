from json import loads
from os.path import join
import bwkeepass as keepass

defaults = {
    'apt': {
        'packages': {
            'kitty-terminfo': {},
        },
    },
    'bash_functions': {
        'h': 'cp /etc/htoprc.global ~/.htoprc; mkdir -p ~/.config/htop; cp /etc/htoprc.global ~/.config/htop/htoprc; htop',
    },
    'users': {
        'root': {
            'home': '/root',
            'shell': '/bin/bash',
            'password': repo.vault.human_password_for('root on {}'.format(node.name)),
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
                'ssh_pubkey': keepass.notes(('ansible', 'authorized_keys', uname)),
                'sudo_commands': {'ALL'},
            }
        elif uname not in metadata_users:
            users[uname] = {
                'delete': True,
            }

    return {
        'users': users,
    }
