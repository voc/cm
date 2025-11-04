files['/usr/local/bin/loudness_rendering'] = {
    'source': 'loudness.sh',
    'mode': '0755',
    'triggers': set(),
}

directories['/opt/loudness-rendering/data'] = {
    'owner': 'voc',
}

files['/opt/loudness-rendering/config.json'] = {
    'content': repo.libs.faults.dict_as_json(node.metadata.get('loudness-rendering')),
}

files['/usr/local/bin/loudness_info_updater'] = {
    'source': 'updater.py',
    'mode': '0755',
}

files['/usr/share/fonts/freesans.ttf'] = {
    # FreeSans, enriched with emojis from Noto Emoji. Encrypted to avoid
    # having to deal with licenses in this repository.
    'content': repo.vault.decrypt_file_as_base64('fonts/freesans.ttf.vault'),
    'content_type': 'base64',
}

for stream, config in node.metadata.get('loudness-rendering/streams').items():
    files[f'/usr/local/lib/systemd/system/{stream}_loudness.service'] = {
        'source': 'service',
        'content_type': 'mako',
        'context': {
            'source_url': config['source'],
            'identifier': stream,
            'output': config['output'],
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
