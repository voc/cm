actions = {
    'nodejs_install_yarn': {
        'command': 'npm install -g yarn@latest',
        'unless': 'test -e /usr/lib/node_modules/yarn',
        'after': {
            'pkg_apt:',
        },
    },
}
