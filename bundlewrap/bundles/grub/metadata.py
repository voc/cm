defaults = {
    'apt': {
        'packages': {
            'grub-pc': {},
        },
    },
    'grub': {
        'cmdline_linux': {
            'console': 'tty0',
            'consoleblank': '0',
            'elevator': 'deadline',
            'net.ifnames': '0',
        },
    },
}
