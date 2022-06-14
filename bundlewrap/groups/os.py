groups['linux'] = {
    'subgroups': {
        'debian',
    },
    'bundles': {
#        'basic',
#        'cron',
#        'nftables',
#        'openssh',
#        'postfix',
#        'sshmon',
#        'sudo',
#        'sysctl',
#        'systemd',
#        'systemd-networkd',
#        'systemd-timers',
#        'telegraf',
#        'users',
    },
    'metadata': {},
    'pip_command': 'pip3',
}

groups['debian'] = {
    'subgroups': {
        'debian-buster',
        'debian-bullseye',
        'debian-sid',
    },
    'bundles': {
#        'apt',
#        'backup-client',
#        'molly-guard',
    },
    'os': 'debian',
}

groups['debian-buster'] = {
    'os_version': (10,)
}

groups['debian-bullseye'] = {
    'os_version': (11,)
}

groups['debian-sid'] = {
    'os_version': (99,)
}
