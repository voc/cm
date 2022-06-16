groups['encoders'] = {
    'member_patterns': {
        r'^encoder[0-9]+$',
    },
    'bundles': {
        'encoder-common',
        'voctocore',
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
        'voctogui',
    },
}
