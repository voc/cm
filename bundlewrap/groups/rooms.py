ROOMS = (
    1,
    2,
    3,
    4,
    5,
    6,
    23, # cccb
    28, # GLT / realraum Graz
    80, # muccc
    81, # hacc
    96, # kunsi
    ('c4', 97),
    98, # derpeter
    191, # seibert
)

for i in ROOMS:
    if isinstance(i, tuple):
        pattern, room_number = i
    else:
        pattern = room_number = i
    groups[f'saal{pattern}'] = {
        'member_patterns': {
            rf'^tallycom{pattern}-[0-9+]$',
            rf'^(encoder|mixer|minion){pattern}$',
        },
        'metadata': {
            'room_number': room_number,
        },
    }


# room-specific metadata
groups['saal28']['metadata']['users'] = {
    'equinox': {},
}

groups['saalc4']['metadata'] = merge_dict(
    groups['saalc4']['metadata'],
    {
        'firewall': {
            'port_rules': {
                '*': {
                    'rfc1918',
                },
            },
        },
        'users': {
            'florob': {},
            'florolf': {},
            'ike': {},
            'qb': {},
            'lukas2511': {},
            'twix': {
                    'uid': 2000,
                    'ssh_pubkeys': [
                            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBmWzl45PCNsqsKxV3Ks4hjbUmkuICsKjE6maZKjW7oU twix@mars"
                        ]
                },
            'kadse': {
                    'uid': 2001,
                    'ssh_pubkeys': [
                            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKmmtGeeNFRf4HKaAVThV3IjGWSJDcji33k4E98vOt5G kadse",
                        ]
                },
            'snoopy': {
                    'uid': 2002,
                    'ssh_pubkeys': [
                            "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIPCe7TJFPCWxRgSklbCPrYU4p/ANPV3t+98oh9+GIKS1AAAABHNzaDo= snoopy@woodstock",
                        ]
                },
        },
    }
)
