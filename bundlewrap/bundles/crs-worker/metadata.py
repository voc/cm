defaults = {
    'apt': {
        'packages': {
            'cifs-utils': {},
            'ffmpeg': {},
            'fuse3': {},
            'fuse-ts': {},
            'libboolean-perl': {},
            'libconfig-inifiles-perl': {},
            'libdatetime-perl': {},
            'libfile-which-perl': {},
            'libipc-run3-perl': {},
            'libjson-perl': {},
            'libmath-round-perl': {},
            'libproc-processtable-perl': {},
            'libwww-curl-perl': {},
            'libxml-rpc-fast-perl': {},
            'libxml-simple-perl': {},
            'ntfs-3g': {},
        },
    },
    'crs-worker': {
        'autostart_scripts': set(),
        'number_of_encoding_workers': 1,
        'use_vaapi': False,
    },
}

if node.has_bundle('zfs'):
    defaults['crs-worker']['systemd_after'] = {
        'zfs-mount.service',
    }


@metadata_reactor.provides(
    'crs-worker/secrets/meta',
)
def derive_secrets_from_encoding(metadata):
    if node.dummy:
        raise DoNotRunAgain
    return {
        'crs-worker': {
            'secrets': {
                'meta': {
                    'token': metadata.get('crs-worker/secrets/encoding/token'),
                    'secret': metadata.get('crs-worker/secrets/encoding/secret'),
                },
            },
        },
    }


@metadata_reactor.provides(
    'crs-worker/systemd_after',
)
def mount_deps_from_cifs_client(metadata):
    return {
        'crs-worker': {
            'systemd_after': {
                f"{config['unitname']}.mount"
                for config in metadata.get('cifs-client/mounts', {}).values()
            },
        },
    }


@metadata_reactor.provides(
    'unit-status-on-login',
)
def unit_status_on_login(metadata):
    return {
        'unit-status-on-login': {
            f'crs-{worker}'
            for worker in metadata.get('crs-worker/autostart_scripts')
        },
    }
