files['/etc/unattended-upgrades-post-hooks.d/nodejs'] = {
    'content_type': 'mako',
    'context': {
        'packages': set(node.metadata.get('nodejs/additional_packages', set())),
    },
    'source': 'unattended-upgrades-post-hook',
    'mode': '0700',
    'triggers': {
        'action:nodejs_install_stuff',
    },
}

actions['nodejs_install_stuff'] = {
    'command': '/etc/unattended-upgrades-post-hooks.d/nodejs',
    'triggered': True,
    'triggered_by': {
        'pkg_apt:nodejs',
    },
}
