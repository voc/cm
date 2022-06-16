defaults = {
    'apt': {
        'packages': {
            'telegraf': {},
        },
        'repos': {
            'influxdb': {
                'items': {
                    'deb https://repos.influxdata.com/{os} {os_release} stable',
                },
            },
        },
    },
}
