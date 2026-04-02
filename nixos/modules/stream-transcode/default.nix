{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.stream-transcode;
  controlConfig = pkgs.writeText "control-config.yaml" ''
    capacity: ${toString cfg.capacity}
    sink: localhost:8080
    configPath: /var/lib/transcode/
    hostname: ${cfg.hostname}
    mqtt:
      hostname: ${cfg.hostname}
  '';
  transcodeConfig = pkgs.writeText "transcode-config.yaml" ''
    mqtt:
      hostname: ${cfg.hostname}
  '';
in
{
  options = {
    services.stream-transcode = {
      enable = mkEnableOption "stream-transcode";
      capacity = mkOption {
        type = types.int;
        default = 1;
        description = "Max number of concurrent transcodes to run.";
      };
      hostname = mkOption {
        type = types.str;
        description = "Hostname to use when registering for transcodings.";
      };
    };
  };

  config = mkIf cfg.enable {
    sops.secrets = {
      mqtt_env = {
        sopsFile = ./secrets.yaml;
        key = "env";
      };
    };
    environment.systemPackages = with pkgs; [
      python313.pkgs.voc-transcode
      libva-utils
      ffmpeg-headless
      stream-api
    ];
    # transcoding config dir
    systemd.tmpfiles.rules = [ "d /var/lib/transcode 0755 root root" ];
    # actual transcoding service, one per stream
    systemd.services."transcode@" = {
      description = "Transcode Stream %I";
      requires = [ "transcode@%i.target" ];
      after = [ "transcode@%i.target" ];
      environment = {
        PYTHONUNBUFFERED = "1";
      };
      startLimitIntervalSec = 0;
      serviceConfig =
        let
          extraPath = lib.makeBinPath [
            pkgs.ffmpeg-headless
            pkgs.libva-utils
          ];
        in
        {
          ExecStart = "${pkgs.python313.pkgs.voc-transcode}/bin/transcode --config ${transcodeConfig} --streamconf /var/lib/transcode/%i -progress http://localhost:9274/progress/%i --restart";
          Restart = "always";
          RestartSec = "5s";
          Environment = "PATH=${extraPath}:$PATH";
          EnvironmentFile = [ config.sops.secrets.mqtt_env.path ];
        };
    };
    systemd.targets."transcode@" = {
      description = "Transcode Stream %I";
      wants = [ "transcode@%i.service" ];
    };
    # starts/stops transcode@ units
    systemd.services."transcode-control" = {
      description = "Transcode Control";
      environment = {
        PYTHONUNBUFFERED = "1";
      };
      startLimitIntervalSec = 0;
      wantedBy = [ "multi-user.target" ];
      restartTriggers = [ config.sops.secrets.mqtt_env.path ];
      restartIfChanged = true;
      serviceConfig = {
        ExecStart = "${pkgs.python313.pkgs.voc-transcode}/bin/transcode-control --config ${controlConfig}";
        Restart = "always";
        RestartSec = "5s";
        EnvironmentFile = [ config.sops.secrets.mqtt_env.path ];
      };
    };
    # exports prometheus metrics about running transcodes
    systemd.services."transcode-exporter" = {
      description = "Transcode Exporter";
      startLimitIntervalSec = 0;
      wantedBy = [ "multi-user.target" ];
      restartIfChanged = true;
      serviceConfig = {
        ExecStart = "${pkgs.stream-api}/bin/transcoding-exporter -listen localhost:9274";
        Restart = "always";
        RestartSec = "5s";
      };
    };
    services.telegraf.extraConfig = {
      inputs = {
        prometheus = [{
          urls = [ "http://localhost:9274/metrics" ];
          metric_version = 1;
          tags = {
            job = "transcode-exporter";
          };
        }];
      };
    };
  };
}
