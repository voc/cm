defaults = {
    'apt': {
        'packages': {
            'dhcpcd5': {
                'installed': False,
            },
            'dphys-swapfile': {
                'installed': False,
            },
            'isc-dhcp-client': {
                'installed': False,
            },
            'isc-dhcp-common': {
                'installed': False,
            },
        },
    },
    'raspberrypi': {
        'default-target': 'multi-user.target',
        'cmdline': {
            'console=tty1',
            'root=/dev/mmcblk0p2',
            'rootfstype=ext4',
            'elevator=deadline',
            'fsck.repair=yes',
            'rootwait',
            'quiet',
            'plymouth.ignore-serial-consoles',
            'net.ifnames=0',
        },
    },
    'systemd': {
        'journal': {
            'storage': 'volatile',
            'maxuse': '100M',
            'keepfree': '100M',
        },
    },
}
