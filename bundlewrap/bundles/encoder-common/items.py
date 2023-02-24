from bundlewrap.exceptions import BundleError

event = node.metadata.get('event/slug')

directories[f'/video'] = {
    'owner': 'voc',
    'group': 'voc',
}

for path in ('capture', 'encoded', 'tmp', 'intros', 'fuse'):
    directories[f'/video/{path}'] = {
        'owner': 'voc',
        'group': 'voc',
    }

    directories[f'/video/{path}/{event}'] = {
        'needed_by': {
            'bundle:voctocore',
            'bundle:crs-worker',
        },
        'owner': 'voc',
        'group': 'voc',
    }
