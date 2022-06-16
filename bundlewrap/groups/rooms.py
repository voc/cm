# rooms with minions
for i in (1, 2, 3, 4, 5, 6, 80):
    groups[f'rooms{i}'] = {
        'members': {
            f'encoder{i}',
            f'mixer{i}',
            f'minion{i}',
        },
        'metadata': {
            'event': {
                'room_name': f'Saal {i}',
                'room_number': i
            },
        },
    }

# rooms without minions
for i in (81, 191):
    groups[f'rooms{i}'] = {
        'members': {
            f'encoder{i}',
            f'mixer{i}',
        },
        'metadata': {
            'event': {
                'room_name': f'Saal {i}',
                'room_number': i
            },
        },
    }
