datacenter = "de"
data_dir = "/opt/consul"
node_name = "{{ ansible_fqdn | replace(".", "-") }}"
log_level  = "INFO"
{% if consul_server|bool %}
server = true
bootstrap_expect = 3
telemetry {
  dogstatsd_addr = "localhost:8125"
  disable_compat_1.9 = true
  disable_hostname = true
  prometheus_retention_time = "60s"
}
{% else %}
server = false
{% endif %}
retry_join = ["{{ consul_servers | join('", "') }}"]
bind_addr = "{{ ansible_nebula.ipv4.address }}"
performance {
  raft_multiplier = 3
}
# make lan-mode behave more like wan-mode
gossip_lan {
  gossip_nodes = 4
  gossip_interval = "500ms"
  probe_timeout = "1s"
  suspicion_mult = 6
}
{% if consul_ui|bool %}
ui_config {
  enabled = true
  content_path = "/consul"
}
{% endif %}