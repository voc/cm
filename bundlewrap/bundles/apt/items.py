from bundlewrap.exceptions import BundleError

supported_os = {
    'debian': {
        10: 'buster',
        11: 'bullseye',
        12: 'bookworm',
        99: 'unstable',
    },
    'raspbian': {
        9: 'stretch',
    }
}

try:
    supported_os[node.os][node.os_version[0]]
except (KeyError, IndexError):
    raise BundleError(f'{node.name}: OS {node.os} {node.os_version} is not supported by bundle:apt')


actions = {
    'apt_update': {
        'command': 'apt-get update',
        'before': {
            'pkg_apt:',
        },
        'triggered': True,
    },
}

files = {
    # Reenable when server case has apt proxy again
    '/etc/apt/apt.conf.d/30detectproxy': {
        'delete': True,
        'needed_by': {
            'pkg_apt:',
        },
    },
    '/etc/apt/detect-apt-proxy.sh': {
        'mode': '0755',
        'needed_by': {
            'pkg_apt:',
        },
    },
    '/etc/apt/preferences.d/c3voc-repo-pinning.pref': {
        'triggers': {
            'action:apt_update',
        },
    },
    '/etc/apt/sources.list': {
        'source': 'sources.list-{}-{}'.format(node.os, supported_os[node.os][node.os_version[0]]),
        'triggers': {
            'action:apt_update',
        },
    },
    '/etc/cloud': {
        'delete': True,
    },
    '/etc/kernel/postinst.d/unattended-upgrades': {
        'source': 'kernel-postinst.d',
        'mode': '0755',
    },
    '/etc/netplan': {
        'delete': True,
    },
    '/usr/local/sbin/do-unattended-upgrades': {
        'mode': '0700',
    },
    '/var/lib/cloud': {
        'delete': True,
    },
}

directories = {
    '/etc/apt/preferences.d': {
        'purge': True,
        'triggers': {
            'action:apt_update',
        },
    },
    '/etc/apt/sources.list.d': {
        'purge': True,
        'triggers': {
            'action:apt_update',
        },
    },
}

svc_systemd = {
    'apt-daily.timer': {
        'running': False,
        'enabled': False,
    },
    'apt-daily-upgrade.timer': {
        'running': False,
        'enabled': False,
    },
}

pkg_apt = {
    'apt-transport-https': {},

    'cloud-init': {
        'installed': False,
    },
    'netplan.io': {
        'installed': False,
    },
}

if node.os_version[0] >= 11:
    symlinks = {
        '/usr/bin/python': {
            'target': '/usr/bin/python3',
            'needs': {
                'pkg_apt:python3',
            },
        },
    }

for name, data in node.metadata.get('apt/repos', {}).items():
    files['/etc/apt/sources.list.d/{}.list'.format(name)] = {
        'content_type': 'mako',
        'content': ("\n".join(sorted(data['items']))).format(
            os=node.os,
            os_release=supported_os[node.os][node.os_version[0]],
        ),
        'triggers': {
            'action:apt_update',
        },
    }

    if data.get('install_gpg_key', True):
        files['/etc/apt/sources.list.d/{}.list'.format(name)]['needs'] = {
            'file:/etc/apt/trusted.gpg.d/{}.list.asc'.format(name),
        }

        files['/etc/apt/trusted.gpg.d/{}.list.asc'.format(name)] = {
            'source': 'gpg-keys/{}.asc'.format(name),
            'triggers': {
                'action:apt_update',
            },
        }

for package, options in node.metadata.get('apt/packages', {}).items():
    pkg_apt[package] = options
