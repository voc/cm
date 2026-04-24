{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

# voc-telemetry module
#
# App to collect anonymous stream telemetry about playback events
# Exposes simple prometheus metrics for monitoring
#
let
  cfg = config.services.voc-telemetry;
  package = inputs.voc-telemetry.defaultPackage.x86_64-linux;
in
{
  options = {
    services.voc-telemetry = {
      enable = mkEnableOption "voc-telemetry";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.voc-telemetry = {
      serviceConfig = {
        ExecStart = "${package}/bin/voc-telemetry -listen 127.0.0.1:7890 -mmdb ${pkgs.ripe-mmdb}/db.mmdb";
      };
      wantedBy = [ "multi-user.target" ];
    };
    services.telegraf.extraConfig = {
      inputs = {
        prometheus = [
          {
            urls = [ "http://localhost:7890/metrics" ];
            metric_version = 1;
            tags = {
              job = "voc-telemetry";
            };
          }
        ];
      };
    };
  };
}
