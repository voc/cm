{
  lib,
  pkgs,
  config,
  ...
}:

let
  fqdn = config.networking.hostName + "." + config.networking.domain;
  basicAuthFile = "/var/lib/nginx_basic_auth";
  vmalertPort = "8880";
  victoriametricsPort = "8428";
  allHosts = map (name: nameToHost name) (lib.attrNames (import ./../../hosts.nix));
  hostsByTag =
    tag:
    map (name: nameToHost name) (
      lib.attrNames (
        lib.filterAttrs (host: deriv: lib.elem tag (getTags host (deriv { }))) (import ./../../hosts.nix)
      )
    );
  getTags =
    name: conf:
    if
      lib.hasAttrByPath [
        "deployment"
        "tags"
      ] conf
    then
      conf.deployment.tags
    else
      [ ];
  nameToHost = name: (builtins.replaceStrings [ "-" ] [ "." ] name) + ".c3voc.de";
  scrapeConfigs =
    let
      blackboxAddr = "localhost:${builtins.toString (config.services.prometheus.exporters.blackbox.port)}";
    in
    [
      {
        job_name = "blackbox-hls";
        file_sd_configs = [ { files = [ "/var/lib/victoriametrics/streams.yml" ]; } ];
        metrics_path = "/probe";
        params = {
          module = [ "http" ];
        };
        relabel_configs = [
          {
            source_labels = [ "__address__" ];
            replacement = "http://live.ber.c3voc.de/hls/$1/native_hd.m3u8";
            target_label = "__param_target";
          }
          {
            source_labels = [ "__address__" ];
            target_label = "stream";
          }
          {
            target_label = "__address__";
            replacement = blackboxAddr;
          }
        ];
      }
      {
        job_name = "blackbox-ipv4";
        static_configs = [ { targets = allHosts; } ];
        metrics_path = "/probe";
        params = {
          module = [ "icmpv4" ];
        };
        relabel_configs = [
          {
            source_labels = [ "__address__" ];
            target_label = "__param_target";
          }
          {
            source_labels = [ "__param_target" ];
            target_label = "instance";
          }
          {
            target_label = "__address__";
            replacement = blackboxAddr;
          }
        ];
      }
      {
        job_name = "blackbox-ipv6";
        static_configs = [ { targets = allHosts; } ];
        metrics_path = "/probe";
        params = {
          module = [ "icmpv6" ];
        };
        relabel_configs = [
          {
            source_labels = [ "__address__" ];
            target_label = "__param_target";
          }
          {
            source_labels = [ "__param_target" ];
            target_label = "instance";
          }
          {
            target_label = "__address__";
            replacement = blackboxAddr;
          }
        ];
      }
      {
        job_name = "alertmanager";
        static_configs = [ { targets = [ "localhost:${builtins.toString config.services.prometheus.alertmanager.port}" ]; } ];
        metrics_path = "/alertmanager/metrics";
      }
      {
        job_name = "vmalert";
        static_configs = [ { targets = [ "localhost:${vmalertPort}" ]; } ];
        metrics_path = "/vmalert/metrics";
      }
    ];
  consulTemplate = pkgs.writeText "consul-template-streams.tpl" ''
      # templated at runtime by consul-template
    - targets: [ [[- range ls "stream/" -]]
      [[- .Key ]],
    [[- end ]] ]
  '';
in
{
  services.monitoring-client = {
    default_output = false; # don't send to ourselves
  };
  services.voc-consul.enable = true;
  services.telegraf.extraConfig = {
    agent.metric_batch_size = 20000;
    agent.metric_buffer_limit = 200000;
    inputs.influxdb_listener = {
      # Address and port to host InfluxDB listener on
      service_address = "127.0.0.1:8186";
      # maximum duration before timing out read of the request
      read_timeout = "10s";
      # maximum duration before timing out write of the response
      write_timeout = "10s";
      parser_type = "upstream";
    };
    # Internal telegraf stats
    inputs.internal = {};
    # Collect nginx status
    inputs.nginx = [ { urls = [ "http://localhost:8999/stats/nginx" ]; } ];
    # Forward to local VictoriaMetrics
    outputs.influxdb = [
      {
        urls = [ "http://localhost:${victoriametricsPort}/victoriametrics" ];
        skip_database_creation = true;
        name_prefix = "telegraf_";
      }
    ];
  };
  services.prometheus.exporters.blackbox = {
    enable = true;
    listenAddress = "localhost";
    configFile = pkgs.writeText "blackbox.yml" (
      lib.generators.toYAML { } {
        modules = {
          http = {
            prober = "http";
            timeout = "10s";
            http = {
              valid_http_versions = [
                "HTTP/1.1"
                "HTTP/2"
              ];
              method = "GET";
            };
          };
          icmpv4 = {
            prober = "icmp";
            icmp = {
              preferred_ip_protocol = "ip4";
              ip_protocol_fallback = false;
            };
          };
          icmpv6 = {
            prober = "icmp";
            icmp = {
              preferred_ip_protocol = "ip6";
              ip_protocol_fallback = false;
            };
          };
        };
      }
    );
  };
  services.victoriametrics = {
    enable = true;
    listenAddress = "localhost:${victoriametricsPort}";
    retentionPeriod = "1y";
    prometheusConfig = {
      global = {
        scrape_interval = "10s";
        scrape_timeout = "10s";
      };
      scrape_configs = scrapeConfigs;
    };
    extraOptions = [
      "-http.pathPrefix=/victoriametrics"
      "-selfScrapeInterval=10s"
      "-vmalert.proxyURL=http://localhost:${vmalertPort}/vmalert"
    ];
  };
  # template stream scrape targets
  services.consul-template.instances.streams = {
    settings = {
      template = [
        {
          source = consulTemplate;
          destination = "/var/lib/victoriametrics/streams.yml";
          command = "systemctl reload prometheus-blackbox-exporter.service";
          left_delimiter = "[[";
          right_delimiter = "]]";
        }
      ];
    };
  };
  sops.secrets.grafana = {
    sopsFile = ./secrets.yaml;
    key = "grafana";
  };
  systemd.services.grafana.serviceConfig.EnvironmentFile = [ config.sops.secrets.grafana.path ];
  systemd.services.grafana.serviceConfig.ExecStartPost =
    pkgs.writeShellScript "fix-socket-perms.sh" ''
      timeout=10
      # Wait for the Grafana socket to be available before starting
      while [ ! -S /run/grafana/grafana.sock ]; do
        sleep 1;
        timeout=$((timeout - 1));
        if [ $timeout -le 0 ]; then
          echo "Timeout waiting for Grafana socket";
          exit 1;
        fi;
      done
      chmod a+rw /run/grafana/grafana.sock;
    '';
  services.grafana = {
    enable = true;
    provision.datasources.settings.datasources = [
      {
        name = "VictoriaMetrics";
        type = "prometheus";
        url = "http://localhost:${victoriametricsPort}/victoriametrics";
      }
      {
        name = "Alertmanager";
        type = "alertmanager";
        url = "http://localhost:${builtins.toString config.services.prometheus.alertmanager.port}/alertmanager";
      }
    ];
    settings = {
      server = {
        protocol = "socket";
        socket = "/run/grafana/grafana.sock";
        domain = fqdn;
        root_url = "https://" + fqdn + "/grafana/";
        serve_from_sub_path = true;
        enable_gzip = true;
      };
      security = {
        admin_user = "$__env{GRAFANA_ADMIN_USER}";
        admin_password = "$__env{GRAFANA_ADMIN_PASSWORD}";
        disable_gravatar = true;
      };
      snapshots.external_enabled = false;
      users.allow_sign_up = false;
      users.allow_org_create = false;
      auth.signout_redirect_url = "https://sso.c3voc.de/application/o/grafana/end-session/";
      "auth.generic_oauth" = {
        name = "C3VOC SSO";
        enabled = true;
        client_id = "$__env{GRAFANA_OAUTH_CLIENT_ID}";
        client_secret = "$__env{GRAFANA_OAUTH_CLIENT_SECRET}";
        scopes = "openid email profile";
        auth_url = "https://sso.c3voc.de/application/o/authorize/";
        token_url = "https://sso.c3voc.de/application/o/token/";
        api_url = "https://sso.c3voc.de/application/o/userinfo/";
        # Map SSO user groups to Grafana roles
        role_attribute_path = "contains(groups, 'infra') && 'Admin' || contains(groups, 'voc') && 'Editor' || 'Viewer'";
      };
    };
  };
  systemd.services.writeAuth = {
    serviceConfig.Type = "oneshot";
    script = ''
      set -a
      . ${config.sops.secrets.monitoring_env.path}
      umask 127
      echo "$MONITORING_PASSWORD" | ${pkgs.apacheHttpd}/bin/htpasswd -iBc ${basicAuthFile} "$MONITORING_USER"
      chown root:nginx ${basicAuthFile}
    '';
    requiredBy = [ "nginx.service" ];
    restartIfChanged = true;
  };
  environment.etc."nginx/index.html".source = ./index.html;
  services.nginx = {
    enable = true;
    upstreams.grafana.servers."unix:/${config.services.grafana.settings.server.socket}" = { };
    upstreams.telegraf.servers."${config.services.telegraf.extraConfig.inputs.influxdb_listener.service_address
    }" =
      { };
    upstreams.oauth-proxy.servers."127.0.0.1:4180" = { };
    upstreams.alertmanager.servers."127.0.0.1:${builtins.toString (config.services.prometheus.alertmanager.port)}" =
      { };
    virtualHosts.${fqdn} = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        extraConfig = ''
          root /etc/nginx;
        '';
      };
      locations."/write" = {
        proxyPass = "http://telegraf";
        extraConfig = ''
          auth_basic "Restricted";
          auth_basic_user_file ${basicAuthFile};
        '';
      };
      locations."~ ^/grafana(.*)$" = {
        # serve static files directly
        root = "${pkgs.grafana}/share/";
        tryFiles = "$uri @grafana";
        extraConfig = ''
          location ~ ^/grafana/public/.*$ {
            try_files $uri @grafana;
            expires 365d;
          }
        '';
      };
      locations."@grafana" = {
        proxyPass = "http://grafana";
        extraConfig = ''
          add_header X-Server "grafana";
        '';
      };
      locations."/oauth2/" = {
        proxyPass = "http://oauth-proxy";
        extraConfig = ''
          proxy_set_header X-Auth-Request-Redirect $request_uri;
        '';
      };
      locations."= /oauth2/auth" = {
        proxyPass = "http://oauth-proxy";
        extraConfig = ''
          proxy_set_header X-Auth-Request-Redirect $request_uri;
          # nginx auth_request includes headers but not body
          proxy_set_header Content-Length   "";
          proxy_pass_request_body           off;
        '';
      };
      locations."/alertmanager" = {
        proxyPass = "http://alertmanager";
        extraConfig = ''
          auth_request /oauth2/auth;
          error_page 401 = @oauth2_signin; #if auth_request returns 401, redirect to sign-in
          auth_request_set $auth_cookie $upstream_http_set_cookie;
          add_header Set-Cookie $auth_cookie;
        '';
      };
      locations."/vmalert" = {
        proxyPass = "http://127.0.0.1:${vmalertPort}";
        extraConfig = ''
          auth_request /oauth2/auth;
          error_page 401 = @oauth2_signin; #if auth_request returns 401, redirect to sign-in
          auth_request_set $auth_cookie $upstream_http_set_cookie;
          add_header Set-Cookie $auth_cookie;
        '';
      };
      locations."/victoriametrics" = {
        proxyPass = "http://127.0.0.1:${victoriametricsPort}";
        extraConfig = ''
          auth_request /oauth2/auth;
          error_page 401 = @oauth2_signin; #if auth_request returns 401, redirect to sign-in
          auth_request_set $auth_cookie $upstream_http_set_cookie;
          add_header Set-Cookie $auth_cookie;
        '';
      };
      # Named location for handling OAuth2 sign-in redirects
      # This ensures the browser receives a proper 302 redirect that it will follow
      locations."@oauth2_signin" = {
        extraConfig = ''
          return 302 /oauth2/sign_in?rd=$scheme://$host$request_uri;
        '';
      };
    };
    # vhost for stats
      appendHttpConfig = ''
        server {
          server_name _;
          listen 127.0.0.1:8999;
          # stats
          location = /stats/nginx {
            stub_status on;
            access_log  off;
            allow ::1;
            allow 127.0.0.1;
            deny all;
          }
        }
      '';
  };
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
