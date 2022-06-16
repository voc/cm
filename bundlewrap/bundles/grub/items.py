cmdline_linux = set()

for opt, value in node.metadata.get('grub/cmdline_linux', {}).items():
    if value is not None:
        cmdline_linux.add(f'{opt}={value}')
    else:
        cmdline_linux.add(opt)

files['/etc/default/grub'] = {
    'content_type': 'mako',
    'context': {
        'cmdline_linux': cmdline_linux,
    },
    'triggers': {
        'action:update_grub',
    },
}

actions['update_grub'] = {
    'triggered': True,
    'command': 'update-grub',
}
