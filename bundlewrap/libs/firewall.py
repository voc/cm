from ipaddress import IPv4Network, ip_network
from os.path import abspath, dirname, join

named_networks = {
    'voc-internal': {
        'ipv4': {
            '10.73.0.0/16',
        },
        'ipv6': {
            '2001:67c:20a1:3504::/64',
        },
    },
    'voc-vpn': {
        'ipv4': {
            '10.8.0.0/24', # openvpn
            '10.9.0.0/16', # wireguard
        },
        'ipv6': set(),
    },
    'rfc1918': {
        'ipv4': {
            '10.0.0.0/8',
            '172.16.0.0/12',
            '192.168.0.0/16',
        },
        'ipv6': {
            'fc00::/7', # actually RFC 4193, but good enough here
        },
    },
}
