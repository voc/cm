directories['/etc/nginx/sites-available'] = {}

directories['/etc/nginx/sites-enabled'] = {
    'purge': True,
    'triggers': {
        'svc_systemd:nginx:restart',
    },
}

directories['/etc/nginx/ssl'] = {
    'purge': True,
    'triggers': {
        'svc_systemd:nginx:restart',
    },
}

directories['/var/www'] = {}

files['/etc/logrotate.d/nginx'] = {
    'content_type': 'mako',
    'source': 'logrotate.conf',
}

files['/etc/nginx/nginx.conf'] = {
    'content_type': 'mako',
    'context': node.metadata.get('nginx'),
    'triggers': {
        'svc_systemd:nginx:restart',
    },
}

files['/etc/nginx/fastcgi.conf'] = {
    'triggers': {
        'svc_systemd:nginx:restart',
    },
}

files['/etc/nginx/sites-available/stub_status'] = {
    'triggers': {
        'svc_systemd:nginx:restart',
    },
}
symlinks['/etc/nginx/sites-enabled/stub_status'] = {
    'target': '/etc/nginx/sites-available/stub_status',
    'triggers': {
        'svc_systemd:nginx:restart',
    },
}

actions['nginx-generate-dhparam'] = {
    'command': 'openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048',
    'unless': 'test -f /etc/ssl/certs/dhparam.pem',
}

svc_systemd['nginx'] = {
    'needs': {
        'action:nginx-generate-dhparam',
        'pkg_apt:nginx',
    },
}

for vhost, config in node.metadata.get('nginx/vhosts', {}).items():
    if not 'domain' in config:
        config['domain'] = vhost


    files[f'/etc/nginx/sites-available/{vhost}'] = {
        'source': 'site_template',
        'content_type': 'mako',
        'context': {
            'additional_config': config.get('additional_config', set()),
            'create_logs': config.get('create_logs', False),
            'domain': config.get('domain', vhost),
            'vhost': vhost,
            'webroot': config.get('webroot', f'/var/www/{vhost}'),
        },
        'needs': set(),
        'needed_by': {
            'svc_systemd:nginx',
            'svc_systemd:nginx:restart',
        },
        'triggers': {
            'svc_systemd:nginx:restart',
        },
    }

    symlinks[f'/etc/nginx/sites-enabled/{vhost}'] = {
        'target': f'/etc/nginx/sites-available/{vhost}',
        'triggers': {
            'svc_systemd:nginx:restart',
        },
    }

    if not 'webroot' in config:
        directories[f'/var/www/{vhost}'] = config.get('webroot_config', {})
