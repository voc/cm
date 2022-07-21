ROOMS_WITHOUT_MINIONS = (
    81,
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
        'metadata': {
            'event': {
                'room_name': f'Saal {i}',
                'room_number': i
            },
            'voctocore': {
                'streaming_endpoint': f's{i}',
            },
        },
    }

    if i in ROOMS_WITH_MINIONS:
        groups[f'saal{i}']['members'].add(f'minion{i}')


groups['server'] = {
    'members': {
        'storage',
    },
}
