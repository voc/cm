# rooms with minions
for i in (1, 2, 3, 4, 5, 6, 80):
    groups[f'saal{i}'] = {
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
            'voctocore': {
                'streaming_endpoint': f's{i}',
            },
        },
    }

# rooms without minions
for i in (81, 191):
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
