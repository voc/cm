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
            'fbcon': 'font:Lat2-Terminus32x16,scrollback:128k',
            'net.ifnames': '0',
        },
    },
}
