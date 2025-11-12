from bundlewrap.exceptions import BundleError

assert node.has_bundle('encoder-common')

WORKER_SCRIPTS = {
    'recording-scheduler': {
        'secret': 'meta',
        'script': 'script-A-recording-scheduler.pl',
    },
    'mount4cut': {
        'secret': 'meta',
        'script': 'script-B-mount4cut.pl',
    },
    'cut-postprocessor': {
        'secret': 'meta',
        'script': 'script-C-cut-postprocessor.pl',
    },
    'postencoding': {
        'secret': 'meta',
        'script': 'script-E-postencoding-auphonic.pl',
    },
    'autochecker': {
        'secret': 'autochecker',
        'script': 'script-X-checking-dummy.pl',
        'environment': {
            'CRS_ISMASTER': 'no',
        },
    }
}

if node.metadata.get('crs-worker/postprocessing_dummy_instead_of_upload', False):
    WORKER_SCRIPTS['upload'] = {
        'secret': 'meta',
        'script': 'script-F-postprocessing-dummy.pl',
    }
else:
    WORKER_SCRIPTS['upload'] = {
        'secret': 'meta',
        'script': 'script-F-upload.pl',
    }

number_of_workers = node.metadata.get('crs-worker/number_of_encoding_workers')
if number_of_workers > 1:
    for i in range(number_of_workers):
        WORKER_SCRIPTS[f'encoding{i}'] = {
            'secret': 'encoding',
            'script': 'script-D-encoding.pl',
        }
else:
    WORKER_SCRIPTS['encoding'] = {
        'secret': 'encoding',
        'script': 'script-D-encoding.pl',
    }

if node.metadata.get('crs-worker/separate_vaapi_worker'):
    WORKER_SCRIPTS['encoding-vaapi'] = {
        'secret': 'vaapi',
        'script': 'script-D-encoding.pl',
        'environment': {
            'CRS_USE_VAAPI': 'yes',
        },
    }


directories['/opt/crs-scripts'] = {}
git_deploy['/opt/crs-scripts'] = {
    'repo': 'https://github.com/voc/crs-scripts.git',
    'rev': 'master',
}

# for HD-Master r22
directories['/usr/local/lib/ladspa'] = {}
files['/usr/local/lib/ladspa/master_me.so'] = {
    'mode': '0755',
    'after': {
        'pkg_apt:ffmpeg',
    },
    'content_type': 'binary',
}

files['/usr/local/lib/systemd/system/restore-fuse-mounts.service'] = {
    'triggers': {
        'action:systemd-reload',
    },
}

files['/home/voc/.ssh/upload-key'] = {
    'content': repo.libs.ssh.generate_ed25519_private_key('upload', node),
    'owner': 'voc',
    'mode': '0600',
}

files['/etc/fuse.conf'] = {}

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
    # only use this for REALLY weird network situations
    'delete': True,
    #'owner': 'voc',
    #'mode': '0700',
}

files['/usr/local/lib/systemd/system/rsync-to-storage@.service'] = {
    # only use this for REALLY weird network situations
    'delete': True,
    #'content_type': 'mako',
    #'context': {
    #    'slug': node.metadata.get('event/slug'),
    #},
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

directories['/etc/crs-scripts'] = {
    'purge': True,
}

autostart_scripts = node.metadata.get('crs-worker/autostart_scripts')
for worker, config in WORKER_SCRIPTS.items():
    if config['secret'] not in node.metadata.get('crs-worker/secrets', {}):
        # no secrets for this worker type available, just ignore it then,
        # except if it was requested to auto-start.
        if worker in autostart_scripts:
            raise BundleError(f'{node.name} requested crs worker {worker} to auto-start, but secrets are missing')
        continue

    environment = {
        'CRS_TRACKER': node.metadata.get('crs-worker/tracker_url'),
        'CRS_TOKEN': node.metadata.get(('crs-worker', 'secrets', config["secret"], 'token')),
        'CRS_SECRET': node.metadata.get(('crs-worker', 'secrets', config["secret"], 'secret')),
        **config.get('environment', {})
    }

    if node.metadata.get('crs-worker/use_vaapi'):
        environment['CRS_USE_VAAPI'] = 'yes'

    if node.metadata.get('crs-worker/room_name', None):
        environment['CRS_ROOM'] = node.metadata.get('crs-worker/room_name')

    files[f'/etc/systemd/system/crs-{worker}.service'] = {
        'delete': True,
        'triggers': {
            'action:systemd-reload',
        },
    }

    files[f'/etc/crs-scripts/{config["secret"]}'] = {
        'content_type': 'mako',
        'source': 'crs-runner.env',
        'context': {
            'env': environment,
        },
        'triggers': set(), # see below
    }

    files[f'/usr/local/lib/systemd/system/crs-{worker}.service'] = {
        'content_type': 'mako',
        'source': 'crs-runner.service',
        'context': {
            'autostart': (worker in autostart_scripts),
            'cpu_pin': node.metadata.get('crs-worker/CPUAffinity', None),
            'script': config['script'],
            'secret': config['secret'],
            'systemd_after': node.metadata.get('crs-worker/systemd_after', set()),
            'worker': worker,
        },
        'triggers': {
            'action:systemd-reload',
            # When changing the 'Install' section of a unit file, the unit
            # needs to be re-enabled to fix the symlinks.
            # Since we cannot know what exactly changed, we simply do
            # that every time the unit file has changed.
            f'action:crs-worker_reenable_worker_{worker}',
        },
    }

    actions[f'crs-worker_reenable_worker_{worker}'] = {
        'command': f'systemctl reenable crs-{worker}',
        'triggered': True,
        'after': {
            f'svc_systemd:crs-{worker}',
        },
        'tags': {
            'causes-downtime',
        },
    }

    if worker in autostart_scripts:
        files[f'/usr/local/lib/systemd/system/crs-{worker}.service']['triggers'].add(
            f'svc_systemd:crs-{worker}:restart',
        )
        files[f'/etc/crs-scripts/{config["secret"]}']['triggers'].add(
            f'svc_systemd:crs-{worker}:restart',
        )

    svc_systemd[f'crs-{worker}'] = {
        # do not start these workers automatically, unless requested
        'running': (True if worker in autostart_scripts else None),
        'needs': {
            f'file:/etc/crs-scripts/{config["secret"]}',
            f'file:/usr/local/lib/systemd/system/crs-{worker}.service',
            'git_deploy:/opt/crs-scripts',
        },
        'tags': {
            'causes-downtime',
        },
    }

files['/usr/local/lib/tmpfiles.d/ffmpeg-progressdir.conf'] = {
    'mode': '0755',
    'needed_by': {
        'action:systemd-tmpfiles-create',
    },
    'triggers': {
        'action:systemd-tmpfiles-create',
    },
}

if autostart_scripts:
    files['/usr/local/sbin/check_system.d/crs-worker-status.sh'] = {
        'content_type': 'mako',
        'context': {
            'scripts': autostart_scripts,
        },
        'mode': '0755',
    }

# delete legacy stuff
files['/opt/tracker-profile.sh'] = {'delete': True}
files['/opt/tracker-profile-meta.sh'] = {'delete': True}
files['/opt/crs-scripts/tracker-profile.sh'] = {'delete': True}
files['/opt/crs-scripts/tracker-profile-meta.sh'] = {'delete': True}
files['/video/upload-key'] = {'delete': True}
files['/video/upload-key.pub'] = {'delete': True}
