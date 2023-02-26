#import re

defaults = {
    'apt': {
        'packages': {
            'linux-headers-amd64': {
                'needed_by': {
                    'pkg_apt:zfs-dkms',
                },
            },
            'zfs-dkms': {
                'needed_by': {
                    'pkg_apt:zfs-zed',
                    'pkg_apt:zfsutils-linux',
                },
            },
            'zfs-zed': {
                'needed_by': {
                    'svc_systemd:zfs-zed',
                    'zfs_dataset:',
                    'zfs_pool:',
                },
            },
            'zfsutils-linux': {
                'needed_by': {
                    'pkg_apt:zfs-zed',
                    'zfs_dataset:',
                    'zfs_pool:',
                },
            },
            'parted': {
                'needed_by': {
                    'zfs_pool:',
                },
            },
        },
    },
    'mqtt-monitoring': {
        'plugins': {
            'zfs_status',
        },
    },
    'systemd-timers': {
        'timers': {
            'zfs-auto-snapshot-daily': {
                'when': 'daily',
                'command': '/usr/local/sbin/zfs-auto-snapshot daily',
            },
            'zfs-auto-snapshot-hourly': {
                'when': 'hourly',
                'command': '/usr/local/sbin/zfs-auto-snapshot hourly',
            },
            'zfs-auto-snapshot-monthly': {
                'when': 'monthly',
                'command': '/usr/local/sbin/zfs-auto-snapshot monthly',
            },
            'zfs-auto-snapshot-weekly': {
                'when': 'weekly',
                'command': '/usr/local/sbin/zfs-auto-snapshot weekly',
            },
        },
    },
    'zfs': {
        'datasets': {},
        'pools': {},
        'snapshots': {
            'retain_defaults': {
                'hourly': 24,
                'daily': 7,
                'weekly': 2,
                'monthly': 1,
            },
        },
    },
}

if node.os == 'debian' and node.os_version[0] <= 10:
    defaults['apt']['repos'] = {
        'backports': {
            'install_gpg_key': False, # default debian signing key
            'items': {
                'deb http://deb.debian.org/debian {os_release}-backports main',
            },
        },
    }

if node.has_bundle('telegraf'):
    defaults['telegraf'] = {
        'input_plugins': {
            'builtin': {
                'zfs': [{
                    'poolMetrics': True,
                }],
            },
            'exec': {
                'zfs-dataset': {
                    'commands': ['sudo /usr/local/sbin/telegraf-per-dataset'],
                    'data_format': 'influx',
                    'timeout': '5s',
                },
            },
        },
        'sudo_commands': {
            '/usr/local/sbin/telegraf-per-dataset',
        },
    }


@metadata_reactor.provides(
    'systemd-timers/timers/zfs-scrub',
)
def scrub_timer(metadata):
    scrubs = [f'zpool scrub {pool}' for pool in sorted(metadata.get('zfs/pools', {}))]
    return {
        'systemd-timers': {
            'timers': {
                'zfs-scrub': {
                    'when': 'Sun 02:00:00 UTC',
                    'command': scrubs,
                },
            },
        },
    }
