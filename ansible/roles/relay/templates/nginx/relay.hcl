services {
  name = "relay-http"
  port = 80
  tags = [{%if stream_master|bool %}"master",{%endif%}]
}

services {
  name = "relay-https"
  port = 443
  tags = [{%if stream_master|bool %}"master",{%endif%}]
}
