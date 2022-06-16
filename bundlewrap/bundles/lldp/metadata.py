defaults = {
    'apt': {
        'packages': {
            'lldpd': {
                'needed_by': {
                    'directory:/etc/lldpd.d',
                    'file:/etc/lldpd.conf',
                    'svc_systemd:lldpd',
                },
            },
        },
    },
}
