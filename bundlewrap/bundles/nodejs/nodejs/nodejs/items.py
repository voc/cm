files['/usr/local/nodejs_install_stuff'] = {
    'content_type': 'mako',
    'context': {
        'packages': set(node.metadata.get('nodejs/additional_packages', set())),
    },
    'mode': '0700',
    'triggers': {
        'action:nodejs_install_stuff',
    },
}

actions['nodejs_install_stuff'] = {
    'command': '/usr/local/nodejs_install_stuff',
    'triggered': True,
    'triggered_by': {
        'pkg_apt:nodejs',
    },
}
