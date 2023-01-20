@metadata_reactor.provides(
    'systemd-timers/timers',
)
def timers_after(metadata):
    timers = {}

    for timer, config in metadata.get('systemd-timers/timers', {}).items():
        timers[timer] = {
            'after': set(config.get('requisite', set())) | set(config.get('requires', set())),
        }

    return {
        'systemd-timers': {
            'timers': timers,
        },
    }
