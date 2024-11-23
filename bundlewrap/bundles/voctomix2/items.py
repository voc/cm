from bundlewrap.exceptions import BundleError

voctomix_version = node.metadata.get('voctomix2/rev', None)

if not voctomix_version:
    raise BundleError(
        f'{node.name}: no voctomix2 version specified. That means that '
        'the automatic selection based on the debian version number '
        f'({node.os_version[0]}) did not yield a result. Please set the '
        'voctomix2 version manually at the node file.'
    )

directories['/opt/voctomix2/release'] = {}

git_deploy['/opt/voctomix2/release'] = {
    'repo': 'https://github.com/voc/voctomix.git',
    'rev': node.metadata.get('voctomix2/rev'),
    'triggers': node.metadata.get('voctomix2/deploy_triggers', set()),
}

directories['/opt/voctomix2/scripts'] = {
    'purge': True,
}
