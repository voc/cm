groups["minisforuminions"] = {
    'members': {
        'minion1',
        'minion2',
        'minion3',
        'minion4',
        'minion5',
        'minion6',

    },
    'bundles': {
        'zfs'
    },
    'metadata': {
        'zfs': {
            "datasets": {
                # NAME               MOUNTPOINT
                # zroot              none
                # zroot/ROOT         none
                # zroot/ROOT/debian  /
                # zroot/home         /home
                # zroot/home/root    /root
                # zroot/var          none
                # zroot/var/cache    /var/cache
                # zroot/var/lib      /var/lib
                # zroot/var/log      /var/log
                "zroot": {},
                "zroot/ROOT": {},
                "zroot/ROOT/debian": {
                    "mountpoint": "/",
                },
                "zroot/home": {
                    "mountpoint": "/home",
                },
                "zroot/home/root": {
                    "mountpoint": "/root",
                },
                "zroot/var": {},
                "zroot/var/cache": {
                    "mountpoint": "/var/cache",
                },
                "zroot/var/lib": {
                    "mountpoint": "/var/lib",
                },
                "zroot/var/log": {
                    "mountpoint": "/var/log",
                },
            },
            "pools": {
                "zroot": {}
            },
        },

    }
}
