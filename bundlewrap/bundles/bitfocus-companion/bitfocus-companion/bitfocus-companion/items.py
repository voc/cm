

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
    # min (incl), max (excl)
    (None, parse('3.0.0')): 'node /opt/bitfocus-companion/headless_ip.js 0.0.0.0',
    (parse('3.0.0'), parse('3.3.0')): ' '.join(
        [
            'node /opt/bitfocus-companion/main.js',
            '--config-dir /var/opt/bitfocus-companion',
            f'--machine-id {node.name}',
            '--log-level info',
            '--extra-module-path /opt/bitfocus-companion/module-local-dev',
        ]
    ),
    (parse('3.3.0'), parse('3.5.0')): ' '.join(
        [
            'node /opt/bitfocus-companion/companion/main.js',
            '--config-dir /var/opt/bitfocus-companion',
            f'--machine-id {node.name}',
            '--log-level info',
            '--extra-module-path /opt/bitfocus-companion/module-local-dev',
        ]
    ),
    (parse('3.3.0'), None): ' '.join(
        [
            'node /opt/bitfocus-companion/dist/main.js',
            '--config-dir /var/opt/bitfocus-companion',
            f'--machine-id {node.name}',
            '--log-level info',
            '--extra-module-path /opt/bitfocus-companion/module-local-dev',
            '--admin-address 0.0.0.0',
            '--admin-port 8000',
        ]
    ),
}

update_cmd = ['tools/upgrade.sh']
database_enforcer_script = 'jq'
if companion_version >= parse('3.5.0'):
    update_cmd = ['yarn', 'ELECTRON=0 yarn dist']
    database_enforcer_script = 'sqlite'

startcmd = None
for (minver, maxver), cmd in startcmd_by_version.items():
    if minver is None:
        if companion_version < maxver:
            startcmd = cmd
            break
    elif maxver is None:
        if companion_version > minver:
            startcmd = cmd
            break
    else:
        if minver <= companion_version < maxver:
            startcmd = cmd
            break

assert isinstance(
    startcmd, str
), f'{node.name}: found no startcmd for bitfocus-companion version {companion_version}'

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
            'startcmd': startcmd,
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
        'delete': True,
    },
    '/var/opt/bitfocus-companion/merge-passwords.sh': {
        'delete': True,
    },
    '/var/opt/bitfocus-companion/merge-passwords': {
        'source': f'merge-passwords-{database_enforcer_script}',
        'owner': 'companion',
        'group': 'companion',
        'mode': '0755',
    },
    '/var/opt/bitfocus-companion/passwords.json': {
        'content': repo.libs.faults.dict_as_json(
            node.metadata.get('bitfocus-companion/enforce_config')
        ),
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
        'command': ' && '.join(
            [
                'cd /opt/bitfocus-companion',
                'corepack enable',
                *update_cmd,
            ]
        ),
        'needs': {
            'action:git-repo_/opt/bitfocus-companion_checkout',
            'action:git-repo_/opt/bitfocus-companion_clone',
            'action:git-repo_/opt/bitfocus-companion_pull',
            'action:nodejs_install_stuff',
            'pkg_apt:nodejs',
        },
        'triggered_by': {
            'action:git-repo_/opt/bitfocus-companion_checkout',
        },
        'triggered': True,
    },
    'bitfocus-companion_remove_old_node_modules': {
        'command': ' && '.join(
            [
                'rm -rf /opt/bitfocus-companion/node_modules',
                'rm -rf /opt/bitfocus-companion/launcher/node_modules',
                'rm -rf /opt/bitfocus-companion/webui/node_modules',
                'rm -rf /usr/local/share/.cache/yarn',
                'rm -rf /root/.cache/*',
                'rm -rf /root/.npm/',
            ]
        ),
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
        "uid": 2048,
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
