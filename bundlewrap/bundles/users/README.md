# bundles/users

This bundle evaluates node metadata to determine which users should
exist on the system.
It will also create a home directory, add ssh keys and deploy shell
configs, if user-specific configuration exists.

## metadata
    'users': {
        'username': {
            'home': '/home/username', # this is the default
            'shell': '/bin/bash', # this is the default
            'groups': {
                # list of groups the user should be in
            },
            'ssh_pubkeys': {
                # list of ssh pubkeys that are allowed to log in
            },
        },
    }

## custom shell config
Deploy your custom config to these paths:

* data/users/files/tmux/username.conf
* data/users/files/fish/username.conf
* data/users/files/bash/username.bashrc
