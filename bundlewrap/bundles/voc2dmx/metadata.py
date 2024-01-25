import bwkeepass as keepass

defaults = {
    'voc2dmx': {
        'mqtt': {
            'host': keepass.url(['ansible', 'mqtt']),
            'user': keepass.username(['ansible', 'mqtt']),
            'password': keepass.password(['ansible', 'mqtt']),
            'topic': '/voc/alert-viri',
        },
        'sacn': {
            'universe': 1,
        },
        'alert': {
            'brightness': 100,
        },
        'rainbow': {
            'enable': True,
            'intensity': 100,
            'brightness': 40,
            'speed': 25,
        },
    },
}
