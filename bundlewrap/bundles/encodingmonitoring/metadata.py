import bwkeepass as keepass

defaults = {
    'unit-status-on-login': {
        'ffmpeg2mqtt',
    },
    'ffmpeg2mqtt': {
        'host': 'mqtt.c3voc.de',
        'user': 'bundlewrap',
        'password': repo.vault.decrypt('encrypt$gAAAAABmk8KmZd6RTiomPYjrNyhGtd7zFFUcWVqeQNozzyhBO8cfIzihu5DczdRHy8HCneXgXA2eYNIEXvp_2561HEJzv7qWB5Tdxxt-ySAA8VUuZB4liqm3CO4gwRgBXUZxMnQYpLsx'),
        'topic': '/voc/ffmpeg/progress',
        'interval': '5',
    },
}
