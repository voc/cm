{ config, lib, pkgs, ... }:

with lib;

# nginx-viewcounter module
#
# Creates an overlay network between rz-nodes using Nebula.
#
let cfg = config.services.nginx-viewcounter;
  fqdn = config.networking.hostName + "." + config.networking.domain;
in {
  options = {
    services.nginx-viewcounter = {
      enable = mkEnableOption "nginx-viewcounter";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      stream-api
    ];
    systemd.services.nginx-viewcounter = {
      serviceConfig = {
        ExecStart = "${pkgs.stream-api}/bin/nginx-syslog-stream-counter";
      };
      wantedBy = [ "multi-user.target" ];
      before = [ "nginx.service" ];
    };
    services.telegraf.extraConfig = {
      inputs = {
        prometheus = [{
          urls = [ "http://localhost:9273/metrics" ];
          metric_version = 1;
          tags = {
            job = "nginx-viewcounter";
          };
        }];
      };
    };
  };
}
