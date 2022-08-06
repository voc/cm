from bundlewrap.exceptions import BundleError

event = node.metadata.get('event/acronym', '')
if not event and node.has_bundle('voctocore'):
    raise BundleError(f'{node.name} bundle:encoder-common requires event/acronym to be set, is "{event}".')

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
