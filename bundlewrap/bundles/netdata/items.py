files = {
    '/etc/netdata/netdata.conf': {
        'triggers': {
            'svc_systemd:netdata:restart',
        },
    },
    '/etc/netdata/.opt-out-from-anonymous-statistics': {
        'content': '',
        'triggers': {
            'svc_systemd:netdata:restart',
        },
    },
}

svc_systemd = {
    'netdata': {
        'needs': {
            'file:/etc/netdata/netdata.conf',
            'pkg_apt:netdata',
        },
    },
}
