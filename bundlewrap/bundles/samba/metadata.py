from bundlewrap.metadata import atomic


defaults = {
    'apt': {
        'packages': {
            'samba',
        }
    }
    'samba': {
        'sperrfix': {
            'ignore': False,
            'sources': atomic({'*'}),
        },
    },
}


@metadata_reactor.provides(
    ('sperrfix', 'bundle_rules', '137/udp'),
    ('sperrfix', 'bundle_rules', '138/udp'),
    ('sperrfix', 'bundle_rules', '139'),
    ('sperrfix', 'bundle_rules', '445'),
)
def sperrfix(metadata):
    if metadata.get('samba/sperrfix/ignore'):
        return {}
    else:
        return {
            'sperrfix': {
                'bundle_rules': {
                    '137/udp': atomic({'sources': set(metadata.get('samba/sperrfix/sources'))}),
                    '138/udp': atomic({'sources': set(metadata.get('samba/sperrfix/sources'))}),
                    '139': atomic({'sources': set(metadata.get('samba/sperrfix/sources'))}),
                    '445': atomic({'sources': set(metadata.get('samba/sperrfix/sources'))}),
                },
            },
        }
