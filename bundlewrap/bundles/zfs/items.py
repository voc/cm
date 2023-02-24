from json import dumps

from bundlewrap.metadata import MetadataJSONEncoder

if node.os == 'debian':
    actions = {
        # For some reason, this module doesn't get auto-loaded on debian,
        # even if installation of zfsutils-linux tries to start
        # zfs-mount.service. We have no choice but to do it manually.
        'modprobe_zfs': {
            'command': 'modprobe zfs',
            'unless': 'lsmod | grep ^zfs',
            'needs': {
                'pkg_apt:zfs-dkms',
            },
            'needed_by': {
                'pkg_apt:zfs-zed',
                'pkg_apt:zfsutils-linux',
                'zfs_dataset:',
                'zfs_pool:',
            },
            'comment': 'If this fails, do a dist-upgrade, reinstall zfs-dkms, reboot',
        },
    }

files = {
    '/etc/modprobe.d/zfs.conf': {
        'source': 'zfs-modprobe.conf',
        'content_type': 'mako',
        'mode': '0755',
    },
    '/etc/systemd/system/zfs-import-scan.service.d/bundlewrap.conf': {
        'source': 'zfs-import-scan-override.service',
        'content_type': 'mako',
        'triggers': {
            'action:systemd-reload',
        },
    },
    '/etc/systemd/system/zfs-zed.service.d/bundlewrap.conf': {
        'source': 'zfs-zed-override.service',
        'triggers': {
            'action:systemd-reload',
            'svc_systemd:zfs-zed:restart'
        },
    },
    '/etc/zfs-snapshot-config.json': {
        'content': dumps(
            node.metadata.get('zfs/snapshots', {}),
            cls=MetadataJSONEncoder,  # turns sets into sorted lists
            indent=4,
            sort_keys=True,
        ) + '\n',
    },
    '/etc/zfs/zed.d/zed.rc': {
        'content': f'ZED_EMAIL_ADDR="{repo.libs.defaults.admin_email}"\nZED_EMAIL_PROG="mail"\nZED_NOTIFY_INTERVAL_SECS=3600\n',
        'mode': '0600',
        'triggers': {
            'svc_systemd:zfs-zed:restart'
        },
    },
    '/usr/local/sbin/telegraf-per-dataset': {
        'mode': '0755',
    },
    '/usr/local/sbin/zfs-auto-snapshot': {
        'mode': '0755',
    },
}

svc_systemd = {
    'zfs-import-scan.service': {
        'needs': {
            'file:/etc/systemd/system/zfs-import-scan.service.d/bundlewrap.conf',
        },
        'before': {
            'svc_systemd:zfs-import-cache.service',
        },
    },
    'zfs-import-cache.service': {
        'running': None,
        'enabled': False,
        'masked': True,
    },
    'zfs-mount.service': {},
    'zfs-zed': {},
    'zfs.target': {
        'running': None,
    },
    'zfs-import.target': {
        'running': None,
    },
}

for name, attrs in node.metadata.get('zfs/datasets', {}).items():
    zfs_datasets[name] = attrs

    if 'mountpoint' not in attrs:
        zfs_datasets[name]['canmount'] = 'off'
        zfs_datasets[name]['mountpoint'] = 'none'
    elif 'canmount' not in attrs:
        zfs_datasets[name]['canmount'] = 'on'

for name, attrs in node.metadata.get('zfs/pools', {}).items():
    zfs_pools[name] = attrs

    if (not node.os == 'debian' or node.os_version[0] > 10) and 'autotrim' not in attrs:
        zfs_pools[name]['autotrim'] = True
