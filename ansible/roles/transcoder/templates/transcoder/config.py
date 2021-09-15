icecast_password = "{{ lookup('keepass', 'ansible/icecast/icedist/source.password') }}"
mqtt_broker = "{{ mqtt.server }}"
mqtt_port = 8883
mqtt_user = "{{ mqtt.username }}"
mqtt_pass = "{{ mqtt.password }}"
mqtt_certs = "/etc/ssl/certs/ca-certificates.crt"
mqtt_host = "{{ ansible_hostname }}"
