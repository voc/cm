kea_config = {
    'Dhcp4': {
        **node.metadata.get('kea-dhcp-server/config'),
        'control-socket': {
            'socket-type': 'unix',
            'socket-name': 'kea4-ctrl-socket'
        },
        'interfaces-config': {
            'interfaces': sorted(node.metadata.get('kea-dhcp-server/subnets', {}).keys()),
        },
        'hooks-libraries': [
            {
                'library': '/usr/lib/x86_64-linux-gnu/kea/hooks/libdhcp_stat_cmds.so'
            },
        ],
        'subnet4': [],
        'loggers': [{
            'name': 'kea-dhcp4',
            'output_options': [{
                # -> journal
                'output': 'stdout',
            }],
            'severity': 'WARN',
        }],
    },
}

for iface, config in sorted(node.metadata.get('kea-dhcp-server/subnets', {}).items()):
    kea_config['Dhcp4']['subnet4'].append({
        'subnet': config['subnet'],
        'id': int(config['id']),
        'pools': [{
            'pool': f'{config["lower"]} - {config["higher"]}',
        }],
        'option-data': [
            {
                'name': k,
                'data': v,
            } for k, v in sorted(config.get('options', {}).items())
        ],
        'reservations': [
            {
                'ip-address': v['ip'],
                'hw-address': v['mac'],
                'hostname': k,
            } for k, v in sorted(node.metadata.get(('kea-dhcp-server', 'fixed_allocations', iface), {}).items())
        ]
    })

files['/etc/kea/kea-dhcp4.conf'] = {
    'content': repo.libs.faults.dict_as_json(kea_config),
    'triggers': {
        'svc_systemd:kea-dhcp4-server:restart',
    },
}

files['/usr/local/bin/kea-lease-list'] = {
    'mode': '0500',
}

svc_systemd['kea-dhcp4-server'] = {
    'needs': {
        'file:/etc/kea/kea-dhcp4.conf',
        'pkg_apt:kea-dhcp4-server',
    },
}
