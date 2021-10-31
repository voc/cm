datacenter = "de"
data_dir = "/opt/consul"
node_name = "{{ ansible_fqdn | replace(".", "-") }}"
log_level  = "INFO"
{% if consul_server|bool %}
server = true
bootstrap_expect=3
ui_config {
  enabled = true
  content_path = "/consul"
}
{% else %}
server = false
{% endif %}
retry_join = ["{{ consul_servers | join('", "') }}"]
bind_addr = "{{ ansible_nebula.ipv4.address }}"
performance {
  raft_multiplier = 5
}
telemetry {
  disable_compat_1.9 = true
}