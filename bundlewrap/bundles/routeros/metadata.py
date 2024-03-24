import re
from json import load
from os.path import join

with open(join(repo.path, 'configs', f'netbox_device_{node.name}.json')) as f:
    netbox = load(f)

ips = {}
ports = {}
vlans = {
    v['name']: {
        'id': v['vid'],
        'delete': False,
        'tagged': set(),
        'untagged': set(),
    }
    for v in netbox['vlans']
}

for port, conf in netbox['interfaces'].items():
    for ip in conf['ips']:
        ips[ip] = {'interface': port}

    if conf['type'] == 'VIRTUAL':
        # these are VLAN interfaces (for management IPs)
        if conf['ips']:
            # this makes management services available in the VLAN
            try:
                vlans[port]['tagged'].add('bridge')
            except KeyError:
                raise ValueError(
                    f'name of virtual interface "{port}" on {node.name} '
                    f'matches none of the known VLANs: {list(vlans.keys())} '
                    '(you probably need to rename the interface in Netbox '
                    'and/or run netbox-dump)'
                )
        # We do not create the actual VLAN interface here, that
        # happens automatically in items.py.
        continue
    elif not conf['enabled'] or not conf['mode']:
        # disable unconfigured ports
        ports[port] = {
            'disabled': True,
            'description': conf.get('description', ''),
        }
        # dont add vlans for this port
        continue
    else:
        ports[port] = {
            'disabled': False,
            'description': conf.get('description', ''),
        }
        if conf.get('ips', []):
            ports[port]['ips'] = set(conf['ips'])
        if conf['type'] in (
            'A_1000BASE_T',
            'A_10GBASE_X_SFPP',
        ):
            ports[port]['hw'] = True

    if conf['untagged_vlan']:
        vlans[conf['untagged_vlan']]['untagged'].add(port)
        if conf['ips']:
            # this makes management services available in the VLAN
            vlans[conf['untagged_vlan']]['tagged'].add('bridge')

    # tagged

    if conf['mode'] == 'TAGGED_ALL':
        tagged = set(vlans.keys()) - {conf['untagged_vlan']}
    else:
        tagged = conf['tagged_vlans']

    for vlan in tagged:
        vlans[vlan]['tagged'].add(port)

        # this makes management services available in the VLAN
        if conf['ips']:
            vlans[vlan]['tagged'].add('bridge')

defaults = {
    'routeros': {
        'ips': ips,
        'ports': ports,
        'vlans': vlans,
    }
}
