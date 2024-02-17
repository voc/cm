import bwkeepass as keepass
from os.path import join

SECRETS_ROOT = join('openvpn-client', 'files')

svc_systemd = {
    'openvpn@voc': {
        'needs': {
            'pkg_apt:openvpn',
            'file:/etc/openvpn/voc.conf',
            'file:/etc/openvpn/ca.crt',
            'file:/etc/openvpn/ta.key',
            "file:/etc/openvpn/node.crt",
            "file:/etc/openvpn/node.key",
        },
    },
}

files = {
    '/etc/openvpn/voc.conf': {
        'triggers': {
            'svc_systemd:openvpn@voc:restart',
        },
    },
    '/etc/openvpn/ca.crt': {
        'content': repo.vault.decrypt_file(join(SECRETS_ROOT, 'ca.crt.vault')),
        'triggers': {
            'svc_systemd:openvpn@voc:restart',
        },
    },
    '/etc/openvpn/ta.key': {
        'content': repo.vault.decrypt_file(join(SECRETS_ROOT, 'ta.key.vault')),
        'triggers': {
            'svc_systemd:openvpn@voc:restart',
        },
    },
    "/etc/openvpn/node.crt": {
        'content': repo.vault.decrypt_file(join(SECRETS_ROOT, 'clients', f'{node.name}.crt.vault')),
        'triggers': {
            'svc_systemd:openvpn@voc:restart',
        },
    },
    "/etc/openvpn/node.key": {
        'content': repo.vault.decrypt_file(join(SECRETS_ROOT, 'clients', f'{node.name}.key.vault')),
        'triggers': {
            'svc_systemd:openvpn@voc:restart',
        },
    },
}
