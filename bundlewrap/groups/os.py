groups['linux'] = {
    'subgroups': {
        'debian',
    },
    'bundles': {
        'grub',
        'locale',
        'mqtt-monitoring',
        'nftables',
        'sudo',
        'sysconfig',
        'sysctl',
        'systemd',
        'systemd-networkd',
        'systemd-timers',
        'telegraf',
        'users',
#        'basic',
#        'cron',
#        'openssh',
#        'postfix',
#        'sshmon',
    },
    'metadata': {
        'firewall': {
            'port_rules': {
                '*': {'voc-internal'},
                '*/udp': {'voc-internal'},
            },
        },
        'telegraf': {
            'influxdb_url': keepass.url(['ansible', 'monitoring', 'write_htpasswd']),
            'influxdb_username': keepass.username(['ansible', 'monitoring', 'write_htpasswd']),
            'influxdb_password': keepass.password(['ansible', 'monitoring', 'write_htpasswd']),
        },
    },
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
