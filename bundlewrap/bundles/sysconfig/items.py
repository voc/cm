from bundlewrap.utils.text import bold, italic, yellow

description = []
event = node.metadata.get('event/slug', None)
if event:
    description.append('Event: {} ({})'.format(
        node.metadata.get('event/name', '?'),
        node.metadata.get('event/slug'),
    ))
    description.append('Room: {}'.format(node.metadata.get('event/room_name', '?')))

if node.has_bundle('voctocore'):
    description.append('')
    description.append(bold('voctocore source config'))
    for name, opts in node.metadata.get('voctocore/sources', {}).items():
        if opts.get('kind', 'decklink') == 'decklink':
            description.append(' {} kind=decklink - input {} @ {}'.format(
                name,
                opts['devicenumber'],
                opts['mode']
            ))
        else:
            description.append(' {} kind={}'.format(
                name,
                yellow(opts['kind']),
            ))

if node.has_bundle('samba'):
    description.append('')
    description.append(bold('samba shares:'))
    for name, opts in node.metadata.get('samba/shares', {}).items():
        description.append(' {} as //{}/{}{}'.format(
            opts['path'],
            node.hostname,
            name,
            ' (writable)' if opts.get('writable', True) else '',
        ))

desc = node.metadata.get('description', [])
if desc:
    description.append('')
    for line in desc:
        description.append('# {}'.format(italic(line)))

files['/etc/hosts'] = {
    'content_type': 'mako',
}

files['/etc/htoprc.global'] = {
    'source': 'htoprc',
}

files['/etc/motd'] = {
    'content_type': 'mako',
    'context': {
        'description': description,
    },
}

files['/etc/modules'] = {
    'content': '\n'.join(node.metadata.get('modules', set())) + '\n',
}

unit_status_on_login = node.metadata.get('unit-status-on-login', set())
if unit_status_on_login:
    files['/usr/local/bin/unit-status-on-login'] = {
        'mode': '0755',
        'content_type': 'mako',
        'context': {
            'units': unit_status_on_login,
        },
    }
else:
    files['/usr/local/bin/unit-status-on-login'] = {
        'delete': True,
    }

files['/etc/node.description'] = {'delete': True}
