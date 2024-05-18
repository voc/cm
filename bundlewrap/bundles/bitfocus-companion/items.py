

try:
    # Arch Linux (possibly future Ubuntu releases)
    from packaging.version import parse
except ModuleNotFoundError:
    # Ubuntu 20.04 and 18.04
    from setuptools._vendor.packaging.version import parse

assert node.has_bundle('nodejs')
assert node.has_bundle('git-repo')

companion_version = parse(node.metadata.get('bitfocus-companion/version'))

startcmd_by_version = {
    2: 'node /opt/bitfocus-companion/headless_ip.js 0.0.0.0',
    3: ' '.join([
        'node /opt/bitfocus-companion/main.js',
        '--config-dir /var/opt/bitfocus-companion',
        f'--machine-id {node.name}',
        '--log-level info',
        '--extra-module-path /opt/bitfocus-companion/module-local-dev',
    ])
}

directories = {
    '/var/opt/bitfocus-companion': {
        'owner': 'companion',
        'group': 'companion'
    },
    '/var/opt/bitfocus-companion/companion': {
        'owner': 'companion',
        'group': 'companion'
    },
    '/opt/bitfocus-companion/module-local-dev': {
        'purge': True,
        'after': {
            'action:git-repo_/opt/bitfocus-companion_checkout',
            'action:git-repo_/opt/bitfocus-companion_clone',
            'action:git-repo_/opt/bitfocus-companion_pull',
        },
    },
}

files = {
    '/usr/local/lib/systemd/system/bitfocus-companion.service': {
        'content_type': 'mako',
        'context': {
            'startcmd': startcmd_by_version[companion_version.major],
        },
        'triggers': {
            'action:systemd-reload',
            'svc_systemd:bitfocus-companion:restart',
        },
    },
    '/etc/systemd/system/bitfocus-companion.service': {
        'delete': True,
        'triggers': {
            'action:systemd-reload',
        },
    },
    '/etc/udev/rules.d/50-companion.rules': {
        'source': f'udev-{companion_version.major}.rules',
        'triggers': {
            'action:bitfocus-companion_udevrules',
        },
    },
    '/var/opt/bitfocus-companion/merge-passwords.py': {
        'owner': 'companion',
        'group': 'companion',
        'mode': '0755',
    },
    '/var/opt/bitfocus-companion/merge-passwords.sh': {
        'delete': True,
    },
    '/var/opt/bitfocus-companion/passwords.json': {
        'content': repo.libs.faults.dict_as_json(node.metadata.get('bitfocus-companion/enforce_config')),
        'needs': {
            'action:bitfocus-companion_yarn',
        },
        'owner': 'companion',
        'group': 'companion',
        'mode': '0400',
        'triggers': {
            'svc_systemd:bitfocus-companion:restart',
        },
    },
}

actions = {
    'bitfocus-companion_udevrules': {
        'command': 'udevadm control --reload-rules',
        'needs': {
            'file:/etc/udev/rules.d/50-companion.rules',
        },
        'triggered': True,
    },
    'bitfocus-companion_yarn': {
        'command': ' && '.join([
            'cd /opt/bitfocus-companion',
            'tools/update.sh',
        ]),
        'needs': {
            'action:git-repo_/opt/bitfocus-companion_checkout',
            'action:git-repo_/opt/bitfocus-companion_clone',
            'action:git-repo_/opt/bitfocus-companion_pull',
            'action:nodejs_install_yarn',
            'pkg_apt:nodejs',
        },
        'triggered_by': {
            'action:git-repo_/opt/bitfocus-companion_checkout',
        },
        'triggered': True,
    },
    'bitfocus-companion_remove_old_node_modules': {
        'command': ' && '.join([
            #'rm -rf /opt/bitfocus-companion/node_modules',
            'rm -rf /usr/local/share/.cache/yarn',
            'rm -rf /root/.cache/*',
            'rm -rf /root/.npm/',
        ]),
        'triggered': True,
        'triggered_by': {
            'action:git-repo_/opt/bitfocus-companion_checkout',
            'action:git-repo_/opt/bitfocus-companion_clone',
            'action:git-repo_/opt/bitfocus-companion_pull',
        },
        'before': {
            'action:bitfocus-companion_yarn',
        },
    },
}

svc_systemd = {
    'bitfocus-companion': {
        'needs': {
            'directory:/var/opt/bitfocus-companion',
            'file:/var/opt/bitfocus-companion/merge-passwords.sh',
            'file:/var/opt/bitfocus-companion/passwords.json',
            'action:bitfocus-companion_yarn',
        },
    },
}

users = {
    'companion': {
        'home': '/var/opt/bitfocus-companion',
        'groups': {
            'plugdev',
        },
    },
}

for plugin, pconfig in node.metadata.get('bitfocus-companion/plugins', {}).items():
    directories[f'/opt/bitfocus-companion/module-local-dev/{plugin}'] = {}

    git_deploy[f'/opt/bitfocus-companion/module-local-dev/{plugin}'] = {
        'needs': {
            'action:git-repo_/opt/bitfocus-companion_checkout',
            'action:git-repo_/opt/bitfocus-companion_clone',
            'action:git-repo_/opt/bitfocus-companion_pull',
            'action:bitfocus-companion_yarn',
        },
        'repo': pconfig['repo'],
        'rev': pconfig['rev'],
        'triggers': {
            f'action:bitfocus_companion_plugin_{plugin}_yarn',
            'svc_systemd:bitfocus-companion:restart',
        },
    }

    actions[f'bitfocus_companion_plugin_{plugin}_yarn'] = {
        'command': ' && '.join([
            f'cd /opt/bitfocus-companion/module-local-dev/{plugin}',
            'yarn install',
        ]),
        'triggered': True,
        'needed_by': {
            'svc_systemd:bitfocus-companion',
        },
    }
