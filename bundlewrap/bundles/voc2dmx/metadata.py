defaults = {
    'unit-status-on-login': {
        'voc2dmx',
    },
    'voc2dmx': {
        'mqtt': {
            'host': repo.libs.defaults.mqtt_hostname,
            'user': repo.libs.defaults.mqtt_username,
            'password': repo.vault.decrypt(repo.libs.defaults.mqtt_password),
            'topic': '/voc/alert-viri',
        },
        'sacn': {
            'universe': 1,
        },
        'alerts': {
            'brightness': 100,
        },
        'rainbow': {
            'enable': True,
            'intensity': 100,
            'brightness': 40,
            'speed': 25,
        },
    },
}
