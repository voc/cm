from packaging.version import parse

assert node.has_bundle('nodejs')

companion_version_str = node.metadata.get('bitfocus-companion/version')
companion_version = parse(companion_version_str)

startcmd_by_version = {
    # min (incl), max (excl)
    (parse('3.5.0'), None): ' '.join(
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

update_cmd = ['yarn', 'ELECTRON=0 yarn dist']
database_enforcer_script = 'sqlite-v3'

if companion_version >= parse('4.0.0'):
    database_enforcer_script = 'sqlite-v4'

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


# ---------- udev rules
files['/etc/udev/rules.d/50-companion.rules'] = {
    'source': f'udev-{companion_version.major}.rules',
    'triggers': {
        'action:bitfocus-companion_udevrules',
    },
}

actions['bitfocus-companion_udevrules'] = {
    'command': 'udevadm control --reload-rules',
    'needs': {
        'file:/etc/udev/rules.d/50-companion.rules',
    },
    'triggered': True,
}


# ---------- deploy stuff
actions['bitfocus-companion_cleanup_before_deploy'] = {
    'command': ' && '.join(
        [
            'rm -rf /usr/local/share/.cache/yarn',
            'rm -rf /root/.cache/*',
            'rm -rf /root/.npm/',
            'rm -rf /opt/bitfocus-companion',
        ]
    ),
    'triggered': True,
}

actions['bitfocus-companion_run_git'] = {
    'command': ' && '.join(
        [
            'mkdir /opt/bitfocus-companion',
            'cd /opt/bitfocus-companion',
            f'GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" git clone --branch {companion_version_str} --depth 1 --no-single-branch https://github.com/bitfocus/companion.git .',
            f'git checkout {companion_version_str}',
        ]
    ),
    'unless': ' && '.join(
        [
            'cd /opt/bitfocus-companion',
            f'git describe --exact-match --tags | grep "^{companion_version_str}$"'
        ]
    ),
    'preceded_by': {
        'action:bitfocus-companion_cleanup_before_deploy',
    },
    'triggers': {
        'action:bitfocus-companion_run_yarn',
    },
}

actions['bitfocus-companion_run_yarn'] = {
    'command': ' && '.join(
        [
            'cd /opt/bitfocus-companion',
            'corepack enable',
            *update_cmd,
        ]
    ),
    'needs': {
        'action:nodejs_install_stuff',
        'pkg_apt:nodejs',
    },
    'triggered': True,
}


# ---------- data directories
directories['/var/opt/bitfocus-companion'] = {
    'owner': 'companion',
    'group': 'companion',
}

directories['/var/opt/bitfocus-companion/companion'] = {
    'owner': 'companion',
    'group': 'companion',
}


# ---------- secrets management
files['/var/opt/bitfocus-companion/merge-passwords'] = {
    'source': f'merge-passwords-{database_enforcer_script}',
    'owner': 'companion',
    'group': 'companion',
    'mode': '0755',
}

files['/var/opt/bitfocus-companion/passwords.json'] = {
    'content': repo.libs.faults.dict_as_json(
        node.metadata.get('bitfocus-companion/enforce_config')
    ),
    'owner': 'companion',
    'group': 'companion',
    'mode': '0400',
    'triggers': {
        'svc_systemd:bitfocus-companion:restart',
    },
}


# ---------- start it
users['companion'] = {
    'home': '/var/opt/bitfocus-companion',
    'groups': {
        'plugdev',
    },
}

files['/usr/local/lib/systemd/system/bitfocus-companion.service'] = {
    'content_type': 'mako',
    'context': {
        'startcmd': startcmd,
    },
    'triggers': {
        'action:systemd-reload',
        'svc_systemd:bitfocus-companion:restart',
    },
}

svc_systemd['bitfocus-companion'] = {
    'needs': {
        'directory:/opt/bitfocus-companion/module-local-dev',
        'directory:/var/opt/bitfocus-companion',
        'file:/usr/local/lib/systemd/system/bitfocus-companion.service',
        'file:/var/opt/bitfocus-companion/merge-passwords',
        'file:/var/opt/bitfocus-companion/passwords.json',
        'action:bitfocus-companion_run_yarn',
    },
}


# ---------- plugins
directories['/opt/bitfocus-companion/module-local-dev'] = {
    'purge': True,
    'needs': {
        'action:bitfocus-companion_run_yarn',
    },
}

for plugin, pconfig in node.metadata.get('bitfocus-companion/plugins', {}).items():
    directories[f'/opt/bitfocus-companion/module-local-dev/{plugin}'] = {}

    git_deploy[f'/opt/bitfocus-companion/module-local-dev/{plugin}'] = {
        'repo': pconfig['repo'],
        'rev': pconfig['rev'],
        'triggers': {
            f'action:bitfocus_companion_plugin_{plugin}_yarn',
            'svc_systemd:bitfocus-companion:restart',
        },
    }

    actions[f'bitfocus_companion_plugin_{plugin}_yarn'] = {
        'command': ' && '.join(
            [
                f'cd /opt/bitfocus-companion/module-local-dev/{plugin}',
                'corepack enable',
                'yarn install',
            ]
        ),
        'triggered': True,
        'needed_by': {
            'svc_systemd:bitfocus-companion',
        },
    }
