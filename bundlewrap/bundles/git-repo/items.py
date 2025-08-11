from bundlewrap.exceptions import BundleError

for path, conf in node.metadata.get('git-repo', {}).items():
    def git(command):
        return f'cd {path} && GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" git {command}'


    directories[path] = {}

    checkout_command = [
        git('fetch')
    ]
    if conf.get('tag', None):
        tag = conf['tag']
        checkout_command.append(git(f'checkout {tag}'))
        checkout_unless = git(f'status | grep "HEAD detached at {tag}$"')
    elif conf.get('branch', None):
        branch = conf['branch']
        checkout_command.append(git(f'checkout {branch}'))
        checkout_unless = git(f'rev-parse --abbrev-ref HEAD | grep "^{branch}$"')
    else:
        raise BundleError(f'git repo {conf["repo"]} is missing branch or tag metadata')

    deploy_triggers = set(conf.get('deploy_triggers', set()))

    actions[f'git-repo_{path}_clone'] = {
        'command': git(f'clone {conf["repo"]} .'),
        'unless': f'test -e {path}/.git',
        'needs': {
            f'directory:{path}',
            'pkg_apt:git',
        },
    }

    actions[f'git-repo_{path}_checkout'] = {
        'command': ' && '.join(checkout_command),
        'unless': checkout_unless,
        'needs': {
            f'action:git-repo_{path}_clone',
        },
        'triggers': deploy_triggers,
    }

    actions[f'git-repo_{path}_pull'] = {
        'command': git('pull'),
        'unless': (
            git('fetch') + ' && ' +
            'fetch_head=$(' + git('rev-parse FETCH_HEAD') + ') && ' +
            'head=$(' + git('rev-parse HEAD') + ') && ' +
            'test "$fetch_head" = "$head"'
        ),
        'needs': {
            f'action:git-repo_{path}_checkout',
        },
        'triggers': deploy_triggers,
    }

    if conf.get('submodule'):
        actions[f'git-repo_{path}_submodule_init'] = {
            'command': git('submodule init'),
            'unless': git('submodule status | grep -v \'^-\''),
            'needs': {
                f'action:git-repo_{path}_checkout',
            },
            'triggers': deploy_triggers,
        }
        actions[f'git-repo_{path}_submodule_update'] = {
            'command':  git(f'submodule update --recursive'),
            'triggered_by': {
                f'action:git-repo_{path}_submodule_init',
                f'action:git-repo_{path}_pull',
            },
            'triggers': deploy_triggers,
            'triggered': True,
        }
