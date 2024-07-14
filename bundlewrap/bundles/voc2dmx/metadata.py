import bwkeepass as keepass

defaults = {
    'unit-status-on-login': {
        'voc2dmx',
    },
    'voc2dmx': {
        'mqtt': {
            'host': 'mqtt.c3voc.de',
            'user': 'bundlewrap',,
            'password': repo.vault.decrypt('encrypt$gAAAAABmk8KmZd6RTiomPYjrNyhGtd7zFFUcWVqeQNozzyhBO8cfIzihu5DczdRHy8HCneXgXA2eYNIEXvp_2561HEJzv7qWB5Tdxxt-ySAA8VUuZB4liqm3CO4gwRgBXUZxMnQYpLsx'),
            'topic': '/voc/alert-viri',
        },
        'sacn': {
            'universe': 1,
        },
        'alerts': {
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
