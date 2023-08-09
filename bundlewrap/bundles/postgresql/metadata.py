defaults = {
    'apt': {
        'repos': {
            'postgresql': {
                'items': {
                    'deb https://apt.postgresql.org/pub/repos/apt/ {os_release}-pgdg main',
                },
            },
        },
    },
    'bash_functions': {
        'pg_query_mon': "watch -n 2 \"echo \\\"SELECT pid, age(clock_timestamp(), query_start), usename, query FROM pg_stat_activity WHERE query != '<IDLE>' AND query NOT ILIKE '%pg_stat_activity%' ORDER BY query_start desc;\\\" | psql postgres\""
    },
    'postgresql': {
        'max_connections': 100,
        'autovacuum_max_workers': 3,
        'maintenance_work_mem': 64,
        'work_mem': 4,
        'shared_buffers': 128,
        'temp_buffers': 8,
        'slow_query_log_sec': 0,
        'cache_size': 256,
    },
}

if node.has_bundle('telegraf'):
    defaults['telegraf'] = {
        'input_plugins': {
            'builtin': {
                'postgresql': [{
                    'address': repo.vault.password_for(f'{node.name} postgresql telegraf').format_into('postgres://telegraf:{}@localhost:5432/telegraf?sslmode=disable'),
                    'ignored_databases': [
                        'template0',
                        'template1',
                        'telegraf',
                    ],
                }],
            },
        },
    }
    defaults['postgresql'].update({
        'roles': {
            'telegraf': {
                'password': repo.vault.password_for(f'{node.name} postgresql telegraf'),
            },
        },
        'databases': {
            'telegraf': {
                'owner': 'telegraf',
            },
        },
    })

if node.has_bundle('zfs'):
    defaults['zfs'] = {
        'datasets': {
            'tank/postgresql': {
                'mountpoint': '/var/lib/postgresql',
                'recordsize': '8192',
            },
        },
    }


@metadata_reactor.provides(
    'postgresql/effective_io_concurrency',
    'postgresql/max_worker_processes',
    'postgresql/max_parallel_workers',
    'postgresql/max_parallel_workers_per_gather',
)
def worker_processes(metadata):
    return {
        'postgresql': {
            # This is the amount of parallel I/O Operations the
            # postgresql process is allowed to do on disk. We set
            # this to max_connections by default.
            'effective_io_concurrency': metadata.get('postgresql/max_connections'),

            # Try to request one worker process per 10 configured
            # connections. The default is 8 for both of these values.
            'max_worker_processes': int(metadata.get('postgresql/max_connections')/10),
            'max_parallel_workers': int(metadata.get('postgresql/max_connections')/10),
            # default 2
            'max_parallel_workers_per_gather': max(int(metadata.get('postgresql/max_connections')/100), 2),
        },
    }
