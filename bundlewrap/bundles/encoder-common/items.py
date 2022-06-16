from bundlewrap.exceptions import BundleError

event = node.metadata.get('event/acronym', '')
if not event:
    raise BundleError(f'{node.name} bundle:encoder-common requires event/acronym to be set, is "{event}".')

for path in ('capture', 'encoded', 'tmp', 'intros', 'fuse'):
    directories[f'/video/{path}/{event}'] = {}
