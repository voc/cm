from bundlewrap.metadata import atomic
from packaging.version import parse

defaults = {
    'apt': {
        'packages': {
            'build-essential': {},
            'cmake': {},
            'libgusb-dev': {},
            'libudev-dev': {},
            'libusb-1.0-0-dev': {},
        },
    },
    'backups': {
        'paths': {
            '/var/opt/bitfocus-companion',
        },
    },
    'bitfocus-companion': {
        'enforce_config': {
            'userconfig': {
                # ensure correct password is set and password auth is
                # enabled
                'admin_lockout': True,
                'admin_timeout': 0,
                'admin_password': repo.vault.human_password_for(
                    f'{node.name} bitfocus-companion password'
                ),
                # always show buttons without page and button number
                'remove_topbar': True,
                # enable some used features
                'usb_hotplug': True,
                'http_api_enabled': True,
            },
        },
    },
    'nodejs': {
        'additional_packages': {
            'semver',
        },
    },
    'zfs': {
        'datasets': {
            'tank/bitfocus-companion': {
                'mountpoint': 'none',
                'canmount': 'off',
            },
            'tank/bitfocus-companion/data': {
                'mountpoint': '/var/opt/bitfocus-companion',
                'needed_by': {
                    'directory:/var/opt/bitfocus-companion',
                },
            },
        },
    },
}


@metadata_reactor.provides(
    'firewall/port_rules',
)
def firewall(metadata):
    if metadata.get('bitfocus-companion/ignore_firewall', False):
        return {}

    return {
        'firewall': {
            'port_rules': {
                '8000/tcp': atomic(metadata.get('bitfocus-companion/restrict-to', set())),
            },
        },
    }


@metadata_reactor.provides(
    'nodejs/version',
)
def nodejs_version(metadata):
    companion_version = parse(metadata.get('bitfocus-companion/version'))

    version_to_nodejs = {
        2: 14,
        3: 18,
        4: 22,
    }

    return {
        'nodejs': {
            'version': version_to_nodejs[companion_version.major],
        },
    }
