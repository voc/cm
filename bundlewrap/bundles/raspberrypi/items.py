default_target = node.metadata.get('raspberrypi/default-target')

# On a FAT filesystem.
file_perms = {
    'owner': None,
    'group': None,
    'mode': None,
}

actions = {
    'raspberrypi_assure_target': {
        'command': f'systemctl set-default {default_target}',
        'unless': f'[ "$(systemctl get-default)" = "{default_target}" ]',
    },
}

files = {
    '/boot/cmdline.txt': {
        'content': ' '.join(sorted(node.metadata.get('raspberrypi/cmdline'))),
        **file_perms,
    },
    '/boot/config.txt': {
        'content_type': 'mako',
        **file_perms,
    },
}
