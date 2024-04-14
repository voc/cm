directories['/opt/voctomix2/release'] = {}

git_deploy['/opt/voctomix2/release'] = {
    'repo': 'https://github.com/voc/voctomix.git',
    'rev': node.metadata.get('voctomix2/rev'),
}

directories['/opt/voctomix2/scripts'] = {
    'purge': True,
}
