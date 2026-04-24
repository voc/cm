{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.services.monitoring-client;
in
# monitoring-client module
#
# Sets up telegraf to report system metrics to the central monitoring server.
#
{
  options = {
    services.monitoring-client = {
      default_output = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether to enable the default monitoring output to monitoring.c3voc.de
        '';
      };
    };
  };

  config = {
    sops.secrets.monitoring_env = {
      sopsFile = ./secret.yaml;
      key = "env";
    };
    services.telegraf = {
      enable = true;
      environmentFiles = [ config.sops.secrets.monitoring_env.path ];
      extraConfig = {
        agent = {
          hostname = config.networking.hostName + "." + config.networking.domain;
          metric_batch_size = lib.mkDefault 1000;
          metric_buffer_limit = lib.mkDefault 10000;
        };
        inputs = {
          cpu = {
            totalcpu = true;
            percpu = false;
          };
          disk = {
            ignore_fs = [
              "tmpfs"
              "devtmpfs"
              "devfs"
              "iso9660"
              "overlay"
              "aufs"
              "squashfs"
            ];
          };
          diskio = { };
          mem = { };
          processes = { };
          swap = { };
          system = { };
          net = {
            interfaces = [ "*" ];
            ignore_protocol_stats = true;
          };
          netstat = { };
        };
        outputs = {
          influxdb = lib.mkIf cfg.default_output {
            urls = [ "https://monitoring.c3voc.de" ];
            skip_database_creation = true;
            username = "\${MONITORING_USER}";
            password = "\${MONITORING_PASSWORD}";
          };
        };
      };
    };
  };
}
