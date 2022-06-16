from inspect import cleandoc
from uuid import UUID

from bundlewrap.utils.text import italic

files = {
    '/etc/hosts': {
        'content_type': 'mako',
    },
    '/etc/htoprc.global': {
        'source': 'htoprc',
    },
    '/etc/motd': {
        'content': '',
    },
}

description = []

# TODO add some more information to this file, for example voc2mix
# config or such

for line in node.metadata.get('description', []):
    description.append('# {}'.format(italic(line)))

if description:
    files['/etc/node.description'] = {
        'content': '\n'.join(description) + '\n',
    }
else:
    files['/etc/node.description'] = {
        'delete': True,
    }
