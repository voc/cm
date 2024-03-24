routeros['/ip/dns'] = {
    'servers': ','.join(repo.libs.defaults.nameservers),
}

for service in (
    'api-ssl',  # slow :(
    'ftp',  # we can download files via HTTP
    'telnet',
    'www-ssl',  # slow :(
    'winbox',
):
    routeros[f'/ip/service?name={service}'] = {
        'disabled': True,
    }

for service in (
    'api',
    'ssh',
    'www',
):
    routeros[f'/ip/service?name={service}'] = {
        'disabled': False,
    }

LOGGING_TOPICS = (
    'critical',
    'error',
    'info',
    'stp',
    'warning',
)

for topic in LOGGING_TOPICS:
    routeros[f'/system/logging?action=memory&topics={topic}'] = {}

if node.metadata.get('routeros/syslog-server', None):
    routeros['/system/logging/action?name=remote'] = {
        'target': 'remote',
        'remote': node.metadata.get('routeros/syslog-server'),
        'remote-port': 514,
    }
    for topic in LOGGING_TOPICS:
        routeros[f'/system/logging?action=remote&topics={topic}'] = {}

routeros['/snmp'] = {
    'enabled': True,
}
routeros['/snmp/community?name=public'] = {
    'addresses': '10.73.0.0/16',
    'disabled': False,
    'read-access': True,
    'write-access': False,
}

routeros['/system/clock'] = {
    'time-zone-autodetect': False,
    'time-zone-name': 'UTC',
}

routeros['/system/identity'] = {
    'name': node.name,
    # doing this first gives us some chance to notice an IP mixup
    'before': {'routeros:'},
}

routeros['/system/ntp/client'] = {
    'enabled': True,
    'server-dns-names': 'de.pool.ntp.org',
}

if node.metadata.get('routeros/gateway'):
    routeros['/ip/route?dst-address=0.0.0.0/0'] = {
        'gateway': node.metadata.get('routeros/gateway'),
    }

routeros['/interface/bridge?name=bridge'] = {
    'protocol-mode': 'none', # disable stp
    'vlan-filtering': True,
}

# assign bridge ports
for port_name, port_conf in node.metadata.get('routeros/ports').items():
    if port_conf.get('delete'):
        routeros[f'/interface/bridge/port?interface={port_name}'] = {
            'delete': True,
            'tags': {'routeros-port'},
            'needs': {f'routeros:/interface?name={port_name}'},
        }
    else:
        pvid = port_conf.get('pvid')
        if not pvid:
            for vlan_name, vlan_conf in node.metadata.get('routeros/vlans').items():
                if port_name in vlan_conf.get('untagged', []):
                    if pvid:
                        raise ValueError(
                            f"{node.name}: port {port_name} untagged "
                            f"in VLANs {pvid} and {vlan_conf['id']}"
                        )
                    else:
                        pvid = vlan_conf['id']

        # Field must not be present of some port types.
        if port_conf.get('hw'):
            hw = {'hw': port_conf['hw']}
        else:
            hw = {}

        routeros[f'/interface/bridge/port?interface={port_name}'] = {
            'bridge': 'bridge',
            '_comment': port_conf.get('description', ''),
            'disabled': False,
            **hw,
            'pvid': pvid or '1',
            'tags': {'routeros-port'},
            'needs': {
                f'routeros:/interface?name={port_name}',
                'routeros:/interface/bridge?name=bridge',
                'tag:routeros-bridge-vlan',  # or we end up with dynamic VLANs after setting pvid to an unknown VLAN
            },
        }

    routeros[f'/interface?name={port_name}'] = {
        '_comment': port_conf.get('description', ''),
        'disabled': port_conf.get('disabled', False)
        and not port_conf.get('delete', False),
    }


# create IPs
for ip, ip_conf in node.metadata.get('routeros/ips').items():
    routeros[f'/ip/address?address={ip}'] = {
        'interface': ip_conf['interface'],
        'tags': {'routeros-ip'},
        'needs': {
            'tag:routeros-vlan',
        },
    }

for vlan, conf in node.metadata.get('routeros/vlans').items():
    if conf['delete']:
        # delete old VLANs
        routeros[f'/interface/vlan?name={vlan}'] = {
            'delete': True,
        }

        routeros[f"/interface/bridge/vlan?vlan-ids={conf['id']}"] = {
            'delete': True,
        }
    else:
        # create vlans
        routeros[f'/interface/vlan?name={vlan}'] = {
            'vlan-id': conf['id'],
            'interface': 'bridge',
            'tags': {'routeros-vlan'},
            'needs': {
                'routeros:/interface/bridge?name=bridge',
            },
        }

        # assign ports to vlans
        routeros[f"/interface/bridge/vlan?vlan-ids={conf['id']}"] = {
            'bridge': 'bridge',
            'untagged': sorted(conf['untagged']),
            'tagged': sorted(conf['tagged']),
            '_comment': vlan,
            'tags': {'routeros-bridge-vlan'},
            'needs': {
                'routeros:/interface/bridge?name=bridge',
                'tag:routeros-vlan',
            },
        }
