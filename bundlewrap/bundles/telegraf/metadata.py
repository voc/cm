defaults = {
    'apt': {
        'packages': {
            'lm-sensors': {},
            'telegraf': {},
        },
        'repos': {
            'influxdb': {
                'items': {
                    'deb https://repos.influxdata.com/{os} stable main',
                },
            },
        },
    },
}
