defaults = {
    'apt': {
        'packages': {
            'smartmontools': {
                'needed_by': {
                    'svc_systemd:smartd',
                },
            },
            'nvme-cli': {
                'needed_by': {
                    'svc_systemd:smartd',
                },
            },
        },
    },
}


# TODO decide if we want this, if yes, turn into systemd timer
#@metadata_reactor.provides(
#    'cron/jobs/smartd',
#)
#def monthly_long_test(metadata):
#    lines = set()
#
#    for number, disk in enumerate(sorted(metadata.get('smartd/disks', set()))):
#        lines.add('0 3 {} * *    root    /usr/sbin/smartctl --test=long {} >/dev/null'.format(
#            number+1, # enumerate() starts at 0
#            disk,
#        ))
#
#    return {
#        'cron': {
#            'jobs': {
#                'smartd': '\n'.join(sorted(lines)),
#            },
#        },
#    }
