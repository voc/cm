for i in [ 1, 2, 3, 4, 5, 6, 80, 81, 191 ]:
    groups[f'rooms{i}'] = {
        'members': {
            f'encoder{i}',
            f'mixer{i}',
            f'minion{i}',
        },
        'metadata': {
            'event': {
                'room_number': i
            },
        },
    }
