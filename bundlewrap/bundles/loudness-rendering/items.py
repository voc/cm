files['/usr/local/bin/loudness_rendering'] = {
    'source': 'loudness.sh',
    'mode': '0755',
    'triggers': set(),
}

for stream, data in node.metadata.get('loudness-rendering').items():
    loudness_target = data["target"]
    source_url = data["source"]
    name = data["name"] if "name" in data else stream

    files[f'/usr/local/lib/systemd/system/{stream}_loudness.service'] = {
        'source': 'service',
        'content_type': 'mako',
        'context': {
            'source_url': source_url,
            'stream_name': name,
            'loudness_target': loudness_target,
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
