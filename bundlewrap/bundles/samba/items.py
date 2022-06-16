svc_systemd = {
    'nmbd': {
        'needs': ['pkg_apt:samba'],
    },
    'smbd': {
        'needs': ['pkg_apt:samba'],
    },
}
svc_restart = ['svc_systemd:nmbd:restart', 'svc_systemd:smbd:restart']

files = {
    '/etc/samba/smb.conf': {
        'content_type': 'mako',
        'triggers': svc_restart,
    },
}

if node.metadata.get('samba', {}).get('create_samba_user', False):
    users = {
        'samba': {},
    }
