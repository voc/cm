defaults = {
    'event': {
        'slug': 'XYZ',
    },
    'mqtt-monitoring': {
        'plugins_daily': {
            'disk_space_usage',
        },
    },
    'systemd-timers': {
        'timers': {
            'clean-up-video-tmp': {
                'command': '/usr/bin/find /video/tmp -type f -mtime +30 -delete',
                'when': 'daily',
            },
        },
    },
}


@metadata_reactor.provides(
    'users/upload/ssh_pubkeys',
)
def upload_keys(metadata):
    pubkeys = set()
    for rnode in repo.nodes:
        if not rnode.has_bundle('crs-worker'):
            continue
        pubkeys.add(repo.libs.ssh.generate_ed25519_public_key('upload', rnode))
    return {
        'users': {
            'upload': {
                'ssh_pubkeys': pubkeys,
            },
        },
    }
