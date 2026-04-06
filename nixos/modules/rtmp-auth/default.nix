{ config, lib, pkgs, ... }:

with lib;

# rtmp-auth module
#
# RTMP-Auth
#
let cfg = config.services.rtmp-auth;
  fqdn = config.networking.hostName + "." + config.networking.domain;
  configFile = pkgs.writeText "config.toml" ''
    [http]
    # List of RTMP apps
    applications = ["stream", "relay"]
    
    # Prefix
    prefix = "/backend"
    
    # Allow insecure
    #insecure = false
    
    [store]
    backend = "consul"
    
    [store.file]
    # Configure file storage path relative to working directory
    #path = "store.db"
  '';
in {
  options = {
    services.rtmp-auth = {
      enable = mkEnableOption "rtmp-auth";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      rtmp-auth
    ];
    sops.secrets = {
      upload_server_config = {
        sopsFile = ./secrets.yaml;
        key = "config";
      };
    };
    systemd.services.rtmp-auth = {
      serviceConfig = {
        ExecStart = "${pkgs.rtmp-auth}/bin/rtmp-auth -config ${configFile}";
      };
      wantedBy = [ "multi-user.target" ];
      restartIfChanged = true;
      restartTriggers = [ configFile ];
    };
  };
}

