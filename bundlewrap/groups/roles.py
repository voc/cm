groups['encoders'] = {
    'member_patterns': {
        r'^encoder[0-9]+$',
    },
    'bundles': {
        'encoder-common',
        'voctocore',
        'samba',
    },
    'metadata': {
        'samba': {
            'restrict-to': {
                'voc-internal',
            },
            'shares': {
                'video': {
                    'comment': 'readonly share of the whole /video',
                    'guest_ok': 'yes',
                    'path': '/video',
                    'additional_options': {
                        'fake oplocks = yes',
                        'locking = no',
                        'read only = yes',
                        'vfs objects = catia fruit',
                    },
                },
                'fuse': {
                    'comment': 'fuse mounting and cutting happens here',
                    'force_group': 'root',
                    'force_user': 'root',
                    'guest_ok': 'yes',
                    'path': '/video/fuse',
                    'additional_options': {
                        'fake oplocks = yes',
                        'locking = no',
                        'read only = no',
                        'vfs objects = catia fruit',
                    },
                },
                'tmp': {
                    'comment': 'temp dir for encoding and repairs',
                    'force_group': 'root',
                    'force_user': 'root',
                    'guest_ok': 'yes',
                    'path': '/video/tmp',
                    'additional_options': {
                        'fake oplocks = yes',
                        'locking = no',
                        'read only = no',
                        'vfs objects = catia fruit',
                    },
                },
                'encoded': {
                    'comment': 'finished video files',
                    'force_group': 'root',
                    'force_user': 'root',
                    'guest_ok': 'yes',
                    'path': '/video/encoded',
                    'additional_options': {
                        'fake oplocks = yes',
                        'locking = no',
                        'read only = no',
                        'vfs objects = catia fruit',
                    },
                },
            },
        },
    },
}

groups['minions'] = {
    'member_patterns': {
        r'^minion[0-9]+$',
    },
    'bundles': {
        'encoder-common',
    },
}

groups['mixers'] = {
    'member_patterns': {
        r'^mixer[0-9]+$',
    },
    'bundles': {
        'mixer-common',
        'voctogui',
    },
}
