for timer, config in node.metadata.get('systemd-timers/timers', {}).items():
    if config.get('delete', False):
        action[f'systemd-timer_stop_timer_{timer}'] = {
            # can't use svc_systemd: here, because that depends on
            # action:systemd-reload
            'command': f'systemctl disable --now {timer}.timer',
            'precedes': {
                # stop, then delete unit files
                'directory:/usr/local/lib/systemd/system',
            },
        }
    else:
        files[f'/usr/local/lib/systemd/system/{timer}.timer'] = {
            'source': 'template.timer',
            'content_type': 'mako',
            'context': {
                'timer': timer,
                'config': config,
            },
            'triggers': {
                'action:systemd-reload',
            },
        }
        files[f'/usr/local/lib/systemd/system/{timer}.service'] = {
            'source': 'template.service',
            'content_type': 'mako',
            'context': {
                'timer': timer,
                'config': config,
            },
            'triggers': {
                'action:systemd-reload',
            },
        }
        svc_systemd[f'{timer}.timer'] = {
            'needs': {
                f'file:/usr/local/lib/systemd/system/{timer}.service',
                f'file:/usr/local/lib/systemd/system/{timer}.timer',
            },
        }
