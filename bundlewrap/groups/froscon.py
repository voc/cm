groups['froscon-servers'] = {
    'members': {
        'froscon-storage',
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

groups['froscon-minions'] = {
    'member_patterns': {
        r'^minion128-\d+$',
    },
    'supergroups': {
        'crs-workers',
        'minions',
        'froscon-servers',
    },
    'bundles': {
        'cifs-client',
    },
    'metadata': {
        'interfaces': {
            'eth0': {
                'gateway4': '10.73.128.201',
            },
        },
        'cifs-client': {
            'mounts': {
                'video': {
                    'serverpath': '//10.73.128.101/video',
                    'mount_options': {
                        'ro': None,
                    },
                },
                'video-encoded': {
                    'serverpath': '//10.73.128.101/encoded',
                },
                'video-fuse': {
                    'serverpath': '//10.73.128.101/fuse',
                },
                'video-tmp': {
                    'serverpath': '//10.73.128.101/tmp',
                },
            },
        },
        'crs-worker': {
            'secrets': {
                'encoding': {
                    'secret': vault.decrypt('encrypt$gAAAAABmk8ICnBbZtrSNdXn1ugJkNBr4Hm8es580zK-QGA_MnTlNZBL21MWCSJlwcveCKjpKGcJeNxJ72HFtTgH10MvNCbKuQdpwFqK_womPBzLIZk-4iS6YscXC2jbi9D41R3REEy2z'),
                    'token': vault.decrypt('encrypt$gAAAAABmk8HyS5oNmGoGlKmNtF7_aVxF1M8f0gzMQvjCIlgl-43nEI6E2-DL_kefbWN_6Y6ncOSXeO5IugOH6ogFxhCf9yxl9kxOhXFTXeXwOUk4gbN3ABZDHeDQB4VIlHJhG7vZy13H'),
                },
            },
        },
    },
}
