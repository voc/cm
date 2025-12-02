defaults = {
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

@metadata_reactor.provides(
    'apt/packages',
)
def grub(metadata):
    if metadata.get("grub/efi", False):
        return {
            'apt': {
                'packages': {
                    'grub-efi-amd64': {},
                },
            },
        }
    else:
        return {
            'apt': {
                'packages': {
                    'grub-pc': {},
                },
            },
        }

