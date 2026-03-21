bitfocus companion
==================

This bundle deploys [Bitfocus Companion](https://bitfocus.io/companion) on video encoders. 
The bundle opens port 8000 for remote control of companion. 
It deploys a default set of buttons and integrations with companion. 
A web interface Password as well as a websockets conection to OBS Studio get configured by passwords read from teamvault or faults.

Required metadata can look like:
```
        'bitfocus-companion': {
            'password': '123abc',
            'sperrfix': {
                'sources': {
                    '10.73.0.0/16',
                    'vpn-users',
                },
            },
        },
        'video-encoder-obs': {
            'websockets': {
                'password': 'cba321',
            },
        },
```
