directories['/opt/voctomix2/release'] = {}

git_deploy['/opt/voctomix2/release'] = {
    'repo': 'https://c3voc.de/git/voctomix',
    'rev': node.metadata.get('voctomix2/rev', 'voctomix2'),
}

directories['/opt/voctomix2/scripts'] = {
    'purge': True,
}
