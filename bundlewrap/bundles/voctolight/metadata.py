from re import match

defaults = {
    'apt': {
        'packages': {
            'python-rpi.gpio': {},
        },
    },
}

m = match(r'^tallycom(\d+)-(\d+)$', node.name)
if m:
    room, cam = m.groups()
    defaults['voctolight'] = {
        'host': f'encoder{room}.lan.c3voc.de',
        'input': f'cam{cam}',
    }
