services {
  name = "http-relay"
  port = 80
  address = "{{ ansible_default_ipv4.address }}"
  tags = [
    {%if relay_origin|bool %}"relay_origin",{%endif%}
    {%if relay_relive_origin|bool %}"relive_origin",{%endif%}
    {%if relay_edge|bool %}"edge",{%endif%}
    {%if icecast|bool %}"icecast",{%endif%}
    {%if relay_local|bool %}"local",{%endif%}
    {%if relay_relive|bool %}"relive",{%endif%}
    {%if relay_dtag|bool %}"dtag",{%endif%}
    {%if relay_thirdparty|bool %}"thirdparty",{%endif%}
    {%if relay_mediastatic|bool %}"mediastatic",{%endif%}
    {%if relay_stats_server|bool %}"stats",{%endif%}
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
    {%if relay_origin|bool %}"relay_origin",{%endif%}
    {%if relay_relive_origin|bool %}"relive_origin",{%endif%}
    {%if relay_edge|bool %}"edge",{%endif%}
    {%if icecast|bool %}"icecast",{%endif%}
    {%if relay_local|bool %}"local",{%endif%}
    {%if relay_relive|bool %}"relive",{%endif%}
    {%if relay_dtag|bool %}"dtag",{%endif%}
    {%if relay_thirdparty|bool %}"thirdparty",{%endif%}
    {%if relay_mediastatic|bool %}"mediastatic",{%endif%}
    {%if relay_stats_server|bool %}"stats",{%endif%}
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
    {%if relay_origin|bool %}"origin",{%endif%}
    {%if relay_edge|bool %}"edge",{%endif%}
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