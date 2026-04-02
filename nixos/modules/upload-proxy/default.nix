{ config, lib, pkgs, ... }:

with lib;

# upload-proxy module
#
# Provides an upload proxy to upload files to the upload-server.
#
let cfg = config.services.upload-proxy;
  configFile = pkgs.writeText "config.toml" ''
  {{- range service "upload-server" }}
  [[sinks]] # {{ .Node }}
  address = "https://{{ .Node | replaceAll "-" "." }}/upload/"
  {{ end }}
'';
in {
  options = {
    services.upload-proxy = {
      enable = mkEnableOption "upload-proxy";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      stream-api
    ];
    sops.secrets = {
      upload_proxy_auth = {
        sopsFile = ./secrets.yaml;
        key = "auth";
      };
    };
    systemd.services.upload-proxy = {
      serviceConfig = {
        ExecStart = "${pkgs.stream-api}/bin/upload-proxy -config /etc/upload-proxy/config.toml -auth-config ${config.sops.secrets.upload_proxy_auth.path}";
        Restart = "on-failure";
        RestartSec = "1s";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
      };
      wantedBy = [ "multi-user.target" ];
      reloadTriggers = [ config.sops.secrets.upload_proxy_auth.path ];
    };
    services.consul-template.instances.upload-proxy = {
      settings = {
        template = [{
          source = configFile;
          destination = "/etc/upload-proxy/config.toml";
          command = "systemctl reload upload-proxy";
          left_delimiter = "{{";
          right_delimiter = "}}";
        }];
      };
    };
    services.telegraf.extraConfig = {
      inputs = {
        prometheus = [{
          urls = [ "http://localhost:8080/metrics" ];
          metric_version = 1;
          tags = {
            job = "upload-proxy";
          };
        }];
      };
    };
  };
}

