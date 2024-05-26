from bundlewrap.metadata import atomic

try:
    # Arch Linux (possibly future Ubuntu releases)
    from packaging.version import parse
except ModuleNotFoundError:
    # Ubuntu 20.04 and 18.04
    from setuptools._vendor.packaging.version import parse

defaults = {
    'apt': {
        'packages': {
            'jq': {},
            'libgusb-dev': {},
            'build-essential': {},
            'cmake': {},
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
                'admin_password': repo.vault.human_password_for(f'{node.name} bitfocus-companion password'),

                # always show buttons without page and button number
                'remove_topbar': True,

                # enable some used features
                'usb_hotplug': True,
                'http_api_enabled': True,
            },
        },
        'sources': [
            'voc-internal',
            "voc-vpn",
        ]
    },
    'git-repo': {
        '/opt/bitfocus-companion': {
            'repo': 'https://github.com/bitfocus/companion.git',
            'submodules': True,
            'deploy_triggers': {
                'svc_systemd:bitfocus-companion:restart',
            },
        },
    },
    'video-encoder-passwords': {
        'passwords': {
            'bitfocus-companion': repo.vault.human_password_for(f'{node.name} bitfocus-companion password'),
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
            'tank/bitfocus-companion/install': {
                'mountpoint': '/opt/bitfocus-companion',
                'needed_by': {
                    'directory:/opt/bitfocus-companion',
                },
            },
        },
    },
}


@metadata_reactor.provides(
    'bitfocus-companion/enforce_config',
)
def obs_config(metadata):
    obs_node = repo.get_node(node.metadata.get('bitfocus-companion/obs_node', node.name))
    if not obs_node.has_bundle('video-encoder-obs'):
        return {}

    if obs_node.name == node.name:
        obs_host = '127.0.0.1'
        m = metadata
    else:
        obs_host = obs_node.hostname
        m = obs_node.metadata

    return {
        'bitfocus-companion': {
            'enforce_config': {
                'instance': {
                    'OBS-Studi': {
                        'instance_type': 'obs-studio',
                        'config': {
                            'host': obs_host,
                            'pass': m.get('video-encoder-obs/websockets/password'),
                            'port': 4444,
                        },
                    },
                },
            },
        },
    }



@metadata_reactor.provides(
    'firewall/port_rules/8000',
)
def sperrfix(metadata):
    if metadata.get('bitfocus-companion/firewall/ignore', False):
        return {}

    sources = metadata.get('bitfocus-companion/sources', set())

    return {
        "firewall": {
            "port_rules": {
                "8000/tcp": sources,
            },
        },
    }


@metadata_reactor.provides(
    'icinga2_api/bitfocus-companion/services/BITFOCUS-COMPANION UPDATE',
)
def icinga_check_for_new_release(metadata):
    return {
        'icinga2_api': {
            'bitfocus-companion': {
                'services': {
                    'BITFOCUS-COMPANION UPDATE': {
                        'command_on_monitored_host': '/usr/local/share/icinga/plugins/check_github_for_new_release bitfocus/companion {}'.format(metadata.get('bitfocus-companion/version')),
                        'check_interval': '60m',
                    },
                },
            },
        },
    }


@metadata_reactor.provides(
    ('git-repo', '/opt/bitfocus-companion', 'tag'),
)
def version_copy_to_other_metadata(metadata):
    return {
        'git-repo': {
            '/opt/bitfocus-companion': {
                'tag': metadata.get('bitfocus-companion/version'),
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
    }

    return {
        'nodejs': {
            'version': version_to_nodejs[companion_version.major],
        },
    }
