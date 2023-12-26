services {
  name = "http-relay"
  port = 80
  address = "{{ ansible_default_ipv4.address }}"
  tags = [
    {%if stream_master|bool %}"stream_master",{%endif%}
    {%if relive_master|bool %}"relive_master",{%endif%}
    {%if stream_edge|bool %}"edge",{%endif%}
    {%if icecast|bool %}"icecast",{%endif%}
    {%if local_relay|bool %}"local",{%endif%}
    {%if relive_relay|bool %}"relive",{%endif%}
    {%if dtag_relay|bool %}"dtag",{%endif%}
    {%if thirdparty_relay|bool %}"thirdparty",{%endif%}
    {%if mediastatic_relay|bool %}"mediastatic",{%endif%}
  ]
  check = {
    id = "nginx-http"
    name = "HTTP health"
    http = "http://localhost/health"
    interval = "5s"
    timeout = "1s"
  }
}

services {
  name = "https-relay"
  port = 443
  address = "{{ ansible_default_ipv4.address }}"
  tags = [
    {%if stream_master|bool %}"stream_master",{%endif%}
    {%if relive_master|bool %}"relive_master",{%endif%}
    {%if stream_edge|bool %}"edge",{%endif%}
    {%if icecast|bool %}"icecast",{%endif%}
    {%if local_relay|bool %}"local",{%endif%}
    {%if relive_relay|bool %}"relive",{%endif%}
    {%if dtag_relay|bool %}"dtag",{%endif%}
    {%if thirdparty_relay|bool %}"thirdparty",{%endif%}
    {%if mediastatic_relay|bool %}"mediastatic",{%endif%}
  ]
  check = {
    id = "nginx-https"
    name = "HTTPs health"
    http = "https://localhost/health"
    tls_server_name = "{{ ansible_fqdn }}"
    interval = "5s"
    timeout = "1s"
  }
}

{% if icecast|bool %}
services {
  name = "icecast"
  port = 8000
  address = "{{ ansible_default_ipv4.address }}"
  tags = [
    {%if stream_master|bool %}"master",{%endif%}
    {%if stream_edge|bool %}"edge",{%endif%}
  ]
  check = {
    id = "icecast"
    name = "Icecast health"
    tcp = "localhost:8000"
    interval = "5s"
    timeout = "1s"
  }
}
{% endif %}