from os.path import join

events = {}

try:
    with open(join(repo_path, 'configs', 'events.txt'), 'r') as fp:
        for line in fp.read().splitlines():
            line = line.strip()

            if line.startswith('#') or ':' not in line:
                continue

            eventname, cases = line.split(':', 1)
            events[eventname.strip()] = set(cases.strip().split(','))
except FileNotFoundError:
    pass

for eventname, cases in events.items():
    groups[eventname] = {
        'subgroups': {
            f'{eventname}-encoders',
            f'{eventname}-mixers',
            f'{eventname}-minions',
        },
    }

    for hw_type in ('encoder', 'mixer', 'minion'):
        groups[f'{eventname}-{hw_type}s'] = {
            'members': {
                f'{hw_type}{casenr}' for casenr in cases
            },
        }
