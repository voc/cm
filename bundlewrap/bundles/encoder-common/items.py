from bundlewrap.exceptions import BundleError

event = node.metadata.get('event/slug', '')

directories[f'/video'] = {
    'owner': 'voc',
    'group': 'voc',
}

for path in ('capture', 'encoded', 'tmp', 'intros', 'fuse'):
    directories[f'/video/{path}'] = {
        'owner': 'voc',
        'group': 'voc',
    }

    if event:
        directories[f'/video/{path}/{event}'] = {
            'needed_by': {
                'bundle:voctocore',
            },
            'owner': 'voc',
            'group': 'voc',
        }
