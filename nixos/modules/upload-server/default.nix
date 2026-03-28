{ config, lib, pkgs, ... }:

with lib;

# upload-server module
#
# Provides an upload server for live stream snippets
#
let cfg = config.services.upload-server;
  fqdn = config.networking.hostName + "." + config.networking.domain;
in {
  options = {
    services.upload-server = {
      enable = mkEnableOption "upload-server";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      stream-api
    ];
    sops.secrets = {
      upload_server_config = {
        sopsFile = ./secrets.yaml;
        key = "config";
      };
    };
    systemd.services.upload-server = {
      serviceConfig = {
        ExecStart = "${pkgs.stream-api}/bin/upload-server -config ${config.sops.secrets.upload_server_config.path}";
      };
      wantedBy = [ "multi-user.target" ];
      restartIfChanged = true;
      restartTriggers = [ config.sops.secrets.upload_server_config.path ];
    };
  };
}

