defaults = {
    'unit-status-on-login': {
        'ffmpeg2mqtt',
    },
    'ffmpeg2mqtt': {
        'host': repo.libs.defaults.mqtt_hostname,
        'user': repo.libs.defaults.mqtt_username,
        'password': repo.vault.decrypt(repo.libs.defaults.mqtt_password),
        'topic': 'voc/ffmpeg/progress/{job}',
        'interval': '5',
    },
}
