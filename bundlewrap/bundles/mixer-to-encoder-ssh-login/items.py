if node.metadata.get('users/voc/ssh_config_verbatim/mixer-to-encoder-ssh-login', set()):
    files['/home/voc/.ssh/mixer-to-encoder-ssh-login'] = {
        'content': repo.libs.ssh.generate_ed25519_private_key('voc', node),
        'owner': 'voc',
        'mode': '0600',
    }
else:
    files['/home/voc/.ssh/mixer-to-encoder-ssh-login'] = {
        'delete': True,
    }
