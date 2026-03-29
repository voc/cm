{
  config,
  lib,
  pkgs,
  fetchurl,
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
in
{
  options = {
    services.voc-telemetry = {
      enable = mkEnableOption "voc-telemetry";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ voc-telemetry ];
    systemd.services.voc-telemetry = {
      serviceConfig = {
        ExecStart = "${pkgs.voc-telemetry}/bin/voc-telemetry -listen 127.0.0.1:7890 -mmdb ${pkgs.ripe-mmdb}/db.mmdb";
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
