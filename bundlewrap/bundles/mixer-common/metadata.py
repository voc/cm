import bwkeepass as keepass

defaults = {
    'users': {
        'mixer': {
            'password': keepass.password(['ansible', 'logins', 'mixer']),
        },
    },
}
