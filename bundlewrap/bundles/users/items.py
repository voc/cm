from os.path import exists, join

files['/etc/bash.bashrc'] = {
    'content_type': 'mako',
}
files['/etc/vim/vimrc.local'] = {}
files['/usr/local/etc/screenrc'] = {}


if node.os_version[0] < 10:
    files['/usr/share/terminfo/x/xterm-kitty'] = {}

for group, attrs in node.metadata.get('groups', {}).items():
    groups[group] = attrs

for username, attrs in node.metadata['users'].items():
    home = attrs.get('home', '/home/{}'.format(username))

    if attrs.get('delete', False):
        users[username] = {'delete': True}
        files[home] = {'delete': True}

    else:
        users[username] = {
            'home': home,
            'shell': attrs.get('shell', '/bin/bash'),
            'uid': attrs.get('uid', None),
            'groups': attrs.get('groups', set()),
        }

        if 'cascade_skip' in attrs:
            users[username]['cascade_skip'] = attrs['cascade_skip']

        if 'password' in attrs:
            users[username]['password'] = attrs['password']
        else:
            users[username]['password_hash'] = 'x' if node.use_shadow_passwords else '*'

        directories[home] = {
            'owner': username,
            'mode': attrs.get('home-mode', '0700'),
        }

        if 'ssh_pubkeys' in attrs:
            files[home + '/.ssh/authorized_keys'] = {
                'content': repo.libs.faults.join_faults(sorted(attrs['ssh_pubkeys']), '\n') + '\n',
                'owner': username,
                'mode': '0600',
            }

        elif not attrs.get('do_not_remove_authorized_keys_from_home', False):
            files[home + '/.ssh/authorized_keys'] = {'delete': True}

        for ftype, fname in {
            'bashrc': '.bashrc',
            'screenrc': '.screenrc',
            'ssh_config': '.ssh/config',
            'tmux-conf': '.tmux.conf',
            'vimrc': '.vimrc',
        }.items():
            if exists(join(repo.path, 'data', 'users', 'files', ftype, username)):
                files[f'{home}/{fname}'] = {
                    'source': f'{ftype}/{username}',
                    'content_type': 'mako',
                    'context': {
                        'verbatim_config': node.metadata.get(f'users/{username}/{ftype}_verbatim', {}),
                    },
                }
            else:
                files[f'{home}/{fname}'] = {
                    'delete': True,
                }

        if attrs.get('enable_linger', False):
            linger_test = ''
            linger_command = 'enable'
        else:
            linger_test = '!'
            linger_command = 'disable'

        actions[f'ensure_linger_state_for_user_{username}'] = {
            'command': f'loginctl {linger_command}-linger {username}',
            'unless': f'{linger_test} test -f /var/lib/systemd/linger/{username}',
            'needs': {
                f'user:{username}',
            },
        }
