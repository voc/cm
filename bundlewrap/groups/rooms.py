ROOMS_WITHOUT_MINIONS = (
    23,
    81,
    98,
    191,
)

ROOMS_WITH_MINIONS = (
    1,
    2,
    3,
    4,
    5,
    6,
    80,
)

for i in ROOMS_WITH_MINIONS + ROOMS_WITHOUT_MINIONS:
    groups[f'saal{i}'] = {
        'members': {
            f'encoder{i}',
            f'mixer{i}',
        },
        'member_patterns': {
            f'^tallycom{i}-[0-9+]$',
        },
        'metadata': {
            'event': {
                'room_number': i
            },
            'voctocore': {
                'streaming_endpoint': f's{i}',
            },
        },
    }

    if i in ROOMS_WITH_MINIONS:
        groups[f'saal{i}']['members'].add(f'minion{i}')
