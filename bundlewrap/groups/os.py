groups['linux'] = {
    'subgroups': {
        'debian',
    },
    'bundles': {
        'grub',
        'locale',
        'mqtt-monitoring',
        'sudo',
        'sysconfig',
        'systemd',
        'systemd-networkd',
        'systemd-timers',
        'users',
#        'basic',
#        'cron',
#        'nftables',
#        'openssh',
#        'postfix',
#        'sshmon',
#        'sysctl',
#        'telegraf',
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
        'apt',
        'molly-guard',
#        'backup-client',
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
