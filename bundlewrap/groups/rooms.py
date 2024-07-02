ROOMS = (
    1,
    2,
    3,
    4,
    5,
    6,
    23, # cccb
    28, # GLT / realraum Graz
    80, # muccc
    81, # hacc
    96, # kunsi
    98, # derpeter
    191, # seibert
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
