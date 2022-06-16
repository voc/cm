# cifs-client
The `cifs-client` bundle will install CIFS/Samba Client and manage cifs mounts
It also creates directories for Mountpoints

## Metadata

    'metadata': {
        'cifs-client': {
            'mounts': {
                'video': {
                    'group': 'voc', # optional
                    'owner': 'voc', # optional
                    'mode': '0755', # optional
                    'mount_options': {  # optional
                        'dir_mode': '0755', # optional
                        'file_mode': '0644', # optional
                        'vers': 3, # optional
                    },
                    'credentials: { # optional
                        'username': 'test',
                        'password': 'foobar123',
                        'domain': 'mycustomer.local',
                    },
                    'mountpoint': '/video', # required
                    'serverpath': '//encoder42.lan.c3voc.de/video', # required
                },
            },
        },
    }
