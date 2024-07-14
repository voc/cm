groups['servercase'] = {
    'members': {
        'router200',
        'storage',
    },
    'metadata': {
        'apt': {
            'packages': {
                'qemu-guest-agent': {},
            },
        },
        'grub': {
            'cmdline_linux': {
                'net.ifnames': '1',
            },
        },
    },
}

groups['minions-servercase'] = {
    'member_patterns': {
        r'^minion200-\d+$',
    },
    'supergroups': {
        'crs-workers',
        'minions',
        'servercase',
    },
    'bundles': {
        'cifs-client',
    },
    'metadata': {
        'interfaces': {
            'ens18': {
                'gateway4': '10.73.0.254',
            },
        },
        'cifs-client': {
            'mounts': {
                'video': {
                    'serverpath': '//10.73.200.24/video',
                    'mount_options': {
                        'ro': None,
                    },
                },
                'video-encoded': {
                    'serverpath': '//10.73.200.24/encoded',
                },
                'video-fuse': {
                    'serverpath': '//10.73.200.24/fuse',
                },
                'video-tmp': {
                    'serverpath': '//10.73.200.24/tmp',
                },
            },
        },
        'crs-worker': {
            'autostart_scripts': {
                'encoding',
            },
            'secrets': {
                'encoding': {
                    'secret': vault.decrypt('encrypt$gAAAAABmk8G3mXWqjGsYc5I2aEHiYb8jyYa3KTyWEQ6JD6sY3XLV3UpIKFG15YhvPI59sTxiTTqOXQjoH4c3Nd7xtSc9pss9N3O8ZQzYA6DrT_xX9tBEMGDBtcS_-tK9T2HEgGjhfu4p'),
                    'token': vault.decrypt('encrypt$gAAAAABmk8GW1nDwpe6FZ4JeA7PBAqtmcfD0C1M3lI8sC8thHfq20jAsG9OztJ2aFCLXjWKuLyulFhK_j7E0WBjHAt0L_qOvTRUEsq3h1NErdzsi-BcARTGJdf8XQlw_atsiq8vY3ofP'),
                },
            },
        },
    },
}
