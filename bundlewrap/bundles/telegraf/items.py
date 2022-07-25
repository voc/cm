telegraf_config = {
    'global_tags': {
        'instance': node.name,
    },
    'agent': {
        'collection_jitter': '0s',
        'debug': False,
        'flush_buffer_when_full': True,
        'flush_interval': '15s',
        'flush_jitter': '0s',
        'hostname': node.name,
        'interval': '15s',
        'metric_batch_size': 1000,
        'metric_buffer_limit': 1_000_000,
        'quiet': False,
        'round_interval': True,
    },
    'inputs': {
        'cpu': [{
            'percpu': False,
            'totalcpu': True,
            'collect_cpu_time': False,
            'report_active': False,
        }],
        'disk': [{
            'ignore_fs': [
                'aufs',
                'devtmpfs',
                'iso9660',
                'nsfs',
                'overlay',
                'squashfs',
                'tmpfs',
            ],
        }],
        'diskio': [{}],
        'kernel': [{}],
        'mem': [{}],
        'net': [{
            'interfaces': node.metadata.get('telegraf/net_limit_interfaces_to', ['*']),
        }],
        'nstat': [{}],
        'processes': [{}],
        'system': [{}],
        'swap': [{}],
        'sensors' [{
            'timeout': '2s',
        }],
        **node.metadata.get('telegraf/input_plugins/builtin', {}),
    },
    'outputs': {
        'influxdb': [{
            'password': node.metadata.get('telegraf/influxdb_password'),
            'skip_database_creation': True,
            'timeout': '10s',
            'urls': [node.metadata.get('telegraf/influxdb_url')],
            'username': node.metadata.get('telegraf/influxdb_username'),
        }],
    },
}

# Bundlewrap can't merge lists. To work around this, telegraf/input_plugins/exec(d)
# is a dict, of which we only use the value of it. This also allows us
# to overwrite values set by metadata defaults/reactors in node and group
# metadata, if needed.
for config in sorted(node.metadata.get('telegraf/input_plugins/exec', {}).values(), key=lambda c: ''.join(c['commands'])):
    if 'exec' not in telegraf_config['inputs']:
        telegraf_config['inputs']['exec'] = []

    telegraf_config['inputs']['exec'].append(config)

files['/etc/telegraf/telegraf.conf'] = {
    'content_type': 'mako',
    'context': {
        'config': telegraf_config,
    },
    'triggers': {
        'svc_systemd:telegraf:restart',
    },
}

svc_systemd['telegraf'] = {
    'needs': {
        'pkg_apt:telegraf',
        'file:/etc/telegraf/telegraf.conf',
    },
}
