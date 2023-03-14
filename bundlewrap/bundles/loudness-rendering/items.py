for stream, source_url in node.metadata.get('loudness-rendering').items():
    files[f'/opt/loudness-rendering/{stream}.sh'] = {
        'source': 'loudness.sh',
        'content_type': 'mako',
        'context': {
            'source_url': source_url,
            'stream_name': stream,
        },
        'needs': {
            'directory:/opt/loudness-rendering',
        },
        'triggers': {
            f'svc_systemd:{stream}_loudness:restart',
        },
        'mode': '0700',
    }
    files[f'/usr/local/lib/systemd/system/{stream}_loudness.service'] = {
        'source': 'service',
        'content_type': 'mako',
        'context': {
            'stream_name': stream,
        },
        'triggers': {
            'action:systemd-daemon-reload',
            f'svc_systemd:{stream}_loudness:restart',
        },
    }

    svc_systemd[f'{stream}_loudness'] = {
        'needs': {
            f'file:/usr/local/lib/systemd/system/{stream}_loudness.service',
        },
    }

directories = {
    '/opt/loudness-rendering': {
        'purge': True,
    },
}
