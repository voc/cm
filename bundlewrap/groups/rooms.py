ROOMS = (
    1,
    2,
    3,
    4,
    5,
    6,
    23, # cccb
    28, # GLT / realraum Graz
    41,
    80, # muccc
    81, # hacc
    94, # sophie
    96, # kunsi
    ('c4', 97),
    98, # derpeter
)

for i in ROOMS:
    if isinstance(i, tuple):
        pattern, room_number = i
    else:
        pattern = room_number = i
    groups[f'saal{pattern}'] = {
        'member_patterns': {
            rf'^tallycom{pattern}-[0-9+]$',
            rf'^(encoder|mixer|minion){pattern}$',
        },
        'metadata': {
            'room_number': room_number,
        },
    }


# room-specific metadata
groups['saal28']['metadata']['users'] = {
    'equinox': {},
}

groups['saalc4']['metadata'] = merge_dict(
    groups['saalc4']['metadata'],
    {
        'firewall': {
            'port_rules': {
                '*': {
                    'rfc1918',
                },
            },
        },
        'nameservers': {
            '172.23.23.1',
        },
        'users': {
            'florob': {},
            'florolf': {},
            'ike': {},
            'kadse': {},
            'lukas2511': {},
            'qb': {},
            'snoopy': {},
            'twix': {},
        },
    }
)
