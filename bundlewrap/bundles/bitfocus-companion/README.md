bitfocus companion
==================

This bundle deploys [Bitfocus Companion](https://bitfocus.io/companion) on video encoders. 
The bundle opens port 8000 for remote control of companion. 
It deploys a default set of buttons and integrations with companion. A web interface Password as well as a websockets conection to OBS Studio get configured by passwords read from teamvault or faults.

Required metadata can look like:
```
        'bitfocus-companion': {
            'password': teamvault.password('123abc'),
            'sperrfix': {
                'sources': {
                    '10.73.0.0/16',
                    'smedia-user-vpn-users',
                },
            },
        },
        'video-encoder-obs': {
            'websockets': {
                'password': teamvault.password('cba321'),
            },
        },
```
