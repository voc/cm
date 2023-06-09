directories['/usr/local/lib/ladspa'] = {}

files['/usr/local/lib/ladspa/master_me.so'] = {
        'mode': '0755',
        'needs': [
            'pkg_apt:ffmpeg',
        ]
    }
