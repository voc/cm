groups['linux'] = {
    'subgroups': {
        'debian',
        # TODO enable this once we have reinstalled all tally pis
        #'raspbian',
    },
    'bundles': {
        'grub',
        'lldp',
        'locale',
        'mqtt-monitoring',
        'nftables',
        'openssh',
        'sudo',
        'sysconfig',
        'sysctl',
        'systemd',
        'systemd-networkd',
        'systemd-timers',
        'telegraf',
        'users',
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
        'debian-bookworm',
        'debian-sid',
    },
    'bundles': {
        'apt',
        'molly-guard',
    },
    'metadata': {
        'mqtt-monitoring': {
            'plugins': {
                'interface_speed',
            },
        },
    },
    'os': 'debian',
}

groups['raspbian'] = {
    'subgroups': {
        'raspbian-stretch',
    },
    'bundles': {
        'apt',
        'molly-guard',
        'raspberrypi',

        # TODO remove these bundles once raspbian is a subgroup of linux
        'mqtt-monitoring',
        'openssh',
        'sudo',
        'sysconfig',
        'systemd',
        'systemd-timers',
        'users',
    },
    'metadata': {
        'users': {
            'pi': {
                'delete': True,
            },
        },
    },
    'os': 'raspbian',
}

groups['raspbian-stretch'] = {
    'os_version': (9,)
}

groups['debian-buster'] = {
    'os_version': (10,)
}

groups['debian-bullseye'] = {
    'os_version': (11,)
}

groups['debian-bookworm'] = {
    'os_version': (12,)
}

groups['debian-sid'] = {
    'os_version': (99,)
}
