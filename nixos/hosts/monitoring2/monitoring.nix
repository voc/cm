{
  lib,
  pkgs,
  config,
  ...
}:

let
  fqdn = config.networking.hostName + "." + config.networking.domain;
  basicAuthFile = "/var/lib/nginx_basic_auth";
  scrapeConfigs = [
    {
      job_name = "blackbox-hls";
      file_sd_configs = [ { files = [ "/var/lib/victoriametrics/blackbox.yml" ]; } ];
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
          replacement = "localhost:${builtins.toString (config.services.prometheus.exporters.blackbox.port)}";
        }
      ];
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
      ## Address and port to host InfluxDB listener on
      service_address = "127.0.0.1:8186";
      ## maximum duration before timing out read of the request
      read_timeout = "10s";
      ## maximum duration before timing out write of the response
      write_timeout = "10s";
      parser_type = "upstream";
    };
    outputs.influxdb = [
      {
        urls = [ "http://localhost:8428" ];
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
        };
      }
    );
  };
  services.victoriametrics = {
    enable = true;
    listenAddress = "localhost:8428";
    retentionPeriod = "1y";
    prometheusConfig = {
      global = {
        scrape_interval = "10s";
        scrape_timeout = "10s";
      };
      scrape_configs = scrapeConfigs;
    };
  };
  # template stream scrape targets
  services.consul-template.instances.streams = {
    settings = {
      template = [
        {
          source = consulTemplate;
          destination = "/var/lib/victoriametrics/blackbox.yml";
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
  systemd.services.grafana.serviceConfig.ExecStartPost = pkgs.writeShellScript "fix-socket-perms.sh" ''
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
        url = "http://localhost:8428";
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
      auth.signout_redirect_url = "https://sso.c3voc.de/application/o/grafana2/end-session/";
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
  services.nginx = {
    enable = true;
    upstreams.grafana.servers."unix:/${config.services.grafana.settings.server.socket}" = { };
    upstreams.telegraf.servers."${config.services.telegraf.extraConfig.inputs.influxdb_listener.service_address
    }" = { };
    upstreams.oauth-proxy.servers."127.0.0.1:4180" = { };
    upstreams.alertmanager.servers."127.0.0.1:${builtins.toString (config.services.prometheus.alertmanager.port)}" =
      { };
    virtualHosts.${fqdn} = {
      enableACME = true;
      forceSSL = true;
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
            expires 365d;
          }
        '';
      };
      locations."@grafana" = {
        proxyPass = "http://grafana";
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
        proxyPass = "http://127.0.0.1:8880";
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
  };
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
