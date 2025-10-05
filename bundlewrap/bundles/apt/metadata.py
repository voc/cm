defaults = {
    'apt': {
        'packages': {
            'at': {},
            'apt-dater-host': {},
            'bc': {},
            'buffer': {},
            'build-essential': {},
            'bwm-ng': {},
            'curl': {},
            'debian-goodies': {},
            'dnsutils': {},
            'dstat': {},
            'ethtool': {},
            'git': {},
            'grep': {},
            'htop': {},
            'iftop': {},
            'iotop': {},
            'iperf': {},
            'irqbalance': {},
            'less': {},
            'libdbd-sqlite3': {},
            'lm-sensors': {},
            'manpages': {},
            'moreutils': {},
            'mosh': {},
            'mtr-tiny': {},
            'ncdu': {},
            'psmisc': {},
            'pv': {},
            'python3': {},
            'python3-dev': {},
            'python3-pip': {
                'needed_by': {
                    'pkg_pip:',
                },
            },
            'python3-setuptools': {
                'needed_by': {
                    'pkg_pip:',
                },
            },
            'python3-virtualenv': {},
            'rsync': {},
            'ruby': {},
            'ruby-dev': {},
            'screen': {},
            'strace': {},
            'systemd': {},
            'tcpdump': {},
            'tmux': {},
            'tree': {},
            'unzip': {},
            'zip': {},

            'bmdtools': {'installed': False,},
            'check-mk-agent': {'installed': False,},
            'dvsink-voc': {'installed': False,},
            'dvsource-voc': {'installed': False,},
            'dvswitch-voc': {'installed': False,},
            'munin-node': {'installed': False,},
            'openntpd': {'installed': False,},
            'popularity-contest': {'installed': False,},
            'puppet': {'installed': False,},
            'rdnssd': {'installed': False,},
            'rpcbind': {'installed': False,},
            'unattended-upgrades': {'installed': False,},
        },
        'repos': {
            'c3voc': {
                'items': {
                    'deb http://pkg.c3voc.de/ {os_release} main',
                },
            },
        },
    },
}

if node.os_version[0] >= 13:
    # provides a year 2038-safe replacement for the traditional Unix "last" utility.
    defaults['apt']['packages']['wtmpdb'] = {}
