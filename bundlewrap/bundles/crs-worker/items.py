assert node.has_bundle('encoder-common')

WORKER_SCRIPTS = {
    'recording-scheduler': 'script-A-recording-scheduler.pl',
    'mount4cut': 'script-B-mount4cut.pl',
    'cut-postprocessor': 'script-C-cut-postprocessor.pl',
    'encoding': 'script-D-encoding.pl',
    'postencoding': 'script-E-postencoding-auphonic.pl',
    'postprocessing': 'script-F-postprocessing-upload.pl',
}

directories['/opt/crs-scripts'] = {}

git_deploy['/opt/crs-scripts'] = {
    'repo': 'https://github.com/crs-tools/crs-scripts.git',
    'rev': 'master',
}

files['/video/upload-key'] = {
    'content_type': 'any', # do not touch file contents
    'owner': 'voc',
    'mode': '0600',
    'unless': '! test -f /video/upload-key',
}

files['/opt/crs-scripts/tracker-profile.sh'] = {
    'content_type': 'mako',
    'source': 'environment',
    'context': {
        'room_name': node.metadata.get('crs-worker/room_name', None),
        'secret': node.metadata.get('crs-worker/secret/encoding'),
        'token': node.metadata.get('crs-worker/token/encoding'),
        'url': node.metadata.get('crs-worker/tracker_url'),
        'vaapi': node.metadata.get('crs-worker/use_vaapi'),
    },
    'needs': {
        'git_deploy:/opt/crs-scripts',
    },
}
files['/opt/crs-scripts/tracker-profile-meta.sh'] = {
    'content_type': 'mako',
    'source': 'environment',
    'context': {
        'url': node.metadata.get('crs-worker/tracker_url'),
        'vaapi': node.metadata.get('crs-worker/use_vaapi'),
        'token': node.metadata.get('crs-worker/token/meta', node.metadata.get('crs-worker/token/encoding')),
        'secret': node.metadata.get('crs-worker/secret/meta', node.metadata.get('crs-worker/secret/encoding')),
    },
    'needs': {
        'git_deploy:/opt/crs-scripts',
    },
}

files['/usr/local/sbin/crs-mount'] = {
    'mode': '0700',
}

files['/usr/local/sbin/rsync-from-encoder'] = {
    'owner': 'voc',
    'mode': '0700',
}

files['/usr/local/lib/systemd/system/rsync-from-encoder@.service'] = {
    'content_type': 'mako',
    'context': {
        'slug': node.metadata.get('event/slug'),
    },
    'triggers': {
        'action:systemd-reload',
    },
}

files['/usr/local/sbin/rsync-to-storage'] = {
    'owner': 'voc',
    'mode': '0700',
}

files['/usr/local/lib/systemd/system/rsync-to-storage@.service'] = {
    'content_type': 'mako',
    'context': {
        'slug': node.metadata.get('event/slug'),
    },
    'triggers': {
        'action:systemd-reload',
    },
}

files['/usr/local/lib/systemd/system/crs-worker.target'] = {
    'triggers': {
        'action:systemd-reload',
    },
}

files['/usr/local/sbin/crs-status'] = {
    'content_type': 'mako',
    'context': {
        'scripts': WORKER_SCRIPTS,
    },
    'mode': '0755',
}

autostart_scripts = node.metadata.get('crs-worker/autostart_scripts', set())
for worker, script in WORKER_SCRIPTS.items():
    files[f'/etc/systemd/system/crs-{worker}.service'] = {
        'delete': True,
        'triggers': {
            'action:systemd-reload',
        },
    }

    files[f'/usr/local/lib/systemd/system/crs-{worker}.service'] = {
        'content_type': 'mako',
        'source': 'crs-runner.service',
        'context': {
            'autostart': (worker in autostart_scripts),
            'script': script,
            'worker': worker,
        },
        'triggers': {
            'action:systemd-reload',
        },
    }

    if worker in autostart_scripts:
        files[f'/usr/local/lib/systemd/system/crs-{worker}.service']['triggers'].add(
            f'svc_systemd:crs-{worker}:restart',
        )

    svc_systemd[f'crs-{worker}'] = {
        # do not start these workers automatically, unless requested
        'running': (True if worker in autostart_scripts else None),
        'needs': {
            'file:/opt/crs-scripts/tracker-profile-meta.sh',
            'file:/opt/crs-scripts/tracker-profile.sh',
            f'file:/usr/local/lib/systemd/system/crs-{worker}.service',
            'git_deploy:/opt/crs-scripts',
        },
    }
