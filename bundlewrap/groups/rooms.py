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
    98, # derpeter
    191, # seibert
)

for i in ROOMS:
    groups[f'saal{i}'] = {
        'member_patterns': {
            rf'^tallycom{i}-[0-9+]$',
            rf'^(encoder|mixer|minion){i}$',
        },
        'metadata': {
            'room_number': i,
        },
    }


# room-specific metadata
groups['saal28']['metadata']['users'] = {
    'equinox': {},
}
