{ lib, config, pkgs, ... }:

{
  sops.secrets.monitoring_env = {
    sopsFile = ./secret.yml;
    key = "env";
  };
  services.telegraf = {
    enable = true;
    environmentFiles = [ config.sops.secrets.monitoring_env.path ];
    extraConfig = {
      inputs = {
        cpu = {
          totalcpu = true;
          percpu = false;
        };
        disk = {
          ignore_fs = [ "tmpfs" "devtmpfs" "devfs" "iso9660" "overlay" "aufs" "squashfs" ];
        };
        diskio = {};
        mem = {};
        processes = {};
        swap = {};
        system = {};
        net = {
          interfaces = [ "*" ];
          ignore_protocol_stats = true;
        };
        netstat = {};
      }
      outputs = {
        influxdb = {
          urls = ["https://monitoring.c3voc.de"];
          skip_database_creation = true;
          username = "\${MONITORING_USER}";
          password = "\${MONITORING_PASSWORD}";
        };
      };
    };
  };
}