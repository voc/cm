files['/usr/local/bin/loudness_rendering'] = {
    'source': 'loudness.sh',
    'mode': '0755',
    'triggers': set(),
}

for stream, source_url in node.metadata.get('loudness-rendering').items():
    files[f'/usr/local/lib/systemd/system/{stream}_loudness.service'] = {
        'source': 'service',
        'content_type': 'mako',
        'context': {
            'source_url': source_url,
            'stream_name': stream,
        },
        'triggers': {
            'action:systemd-reload',
            f'svc_systemd:{stream}_loudness:restart',
        },
    }

    svc_systemd[f'{stream}_loudness'] = {
        'needs': {
            f'file:/usr/local/lib/systemd/system/{stream}_loudness.service',
        },
    }

    files['/usr/local/bin/loudness_rendering']['triggers'].add(f'svc_systemd:{stream}_loudness:restart')
