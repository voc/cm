groups['encoders'] = {
    'member_patterns': {
        r'^encoder[0-9]+$',
    },
    'bundles': {
        'rsync',
        'samba',
        'voctocore',
        'voctocore-artwork',
        'voctomix2',
    },
    'metadata': {
        'voctocore': {
            'streaming_auth_key': keepass.password(['ansible', 'icecast', 'icedist', 'source']),
        },
    },
}

groups['minions'] = {
    'member_patterns': {
        r'^minion[0-9]+$',
    },
}

groups['mixers'] = {
    'member_patterns': {
        r'^mixer[0-9]+$',
    },
    'bundles': {
        'mixer-common',
        'voctogui',
        'voctomix2',
    },
}

groups['crs-workers'] = {
    'subgroups': {
        'encoders',
        'minions',
    },
    'bundles': {
        'crs-worker',
        'encoder-common',
    },
    'metadata': {
        'crs-worker': {
            'tracker_url': 'https://tracker.c3voc.de/rpc',
        },
    },
}
