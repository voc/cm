{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:

with lib;

let
in
{
  imports = [
    "${modulesPath}/virtualisation/proxmox-image.nix"
    ../../profiles/server
    ../../modules/srtrelay
    ../../modules/rtmp-auth
  ];
  config = {
    system.stateVersion = "25.11"; # do not touch
    deployment.tags = [ ];

    #services.srtrelay.enable = true;
    #services.rtmp-auth.enable = true;

    sops.secrets = {
      htpasswd = {
        sopsFile = ./secrets.yaml;
        key = "htpasswd";
      };
    };

    services.nginx.enable = true;
    services.nginx.virtualHosts."ingest.alb.c3voc.de" = {
      forceSSL = true;
      enableACME = true;
      locations."/backend/" = {
        proxyPass = "http://127.0.0.1:8082";
        extraConfig = ''
          auth_basic "stream-api login";
          auto_basic_user_file ${config.sops.secrets.htpasswd.path};
        '';
      };
      locations."/stats/" = {
        proxyPass = "http://127.0.0.1:9999";
        extraConfig = ''
          auth_basic "stream-api login";
          auto_basic_user_file ${config.sops.secrets.htpasswd.path};
        '';
      };
      locations."/stats/srt" = {
        proxyPass = "http://127.0.0.1:8084/streams";
        extraConfig = ''
          auth_basic "stream-api login";
          auto_basic_user_file ${config.sops.secrets.htpasswd.path};
        '';
      };
    };

    networking.hostName = lib.mkOverride 1 "ingest";
    networking.domain = "alb.c3voc.de";
  };
}
