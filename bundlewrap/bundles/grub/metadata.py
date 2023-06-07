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
            'fbcon': 'font:ter-132n,scrollback:128k',
            'net.ifnames': '0',
        },
    },
}
