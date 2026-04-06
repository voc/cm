{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.voc-ingest;
  streamApiConfigFile = pkgs.writeText "config.yml" ''
    publisher:
      enable: yes
      sources:
        - type: icecast
          url: http://localhost:8000
        - type: srtrelay
          url: http://localhost:8084
  '';
  
in
{
  options = {
    services.voc-ingest = {
      enable = mkEnableOption "voc-ingest";
    };
  };

  config = mkIf cfg.enable {
    # enable nebula
    services.voc-nebula.enable = true;
    # enable consul
    services.voc-consul.enable = true;

    services.telegraf.extraConfig = {
      global_tags.role = "ingest";
    };

    services.srtrelay.enable = true;
    services.rtmp-auth.enable = true;

    sops.secrets = {
      htpasswd = {
        sopsFile = ./secrets.yaml;
        key = "htpasswd";
        owner = "nginx";
      };
    };

    services.nginx.enable = true;
    services.nginx.virtualHosts."${config.networking.hostName}.${config.networking.domain}" = {
      forceSSL = true;
      enableACME = true;
      locations."/backend/" = {
        proxyPass = "http://127.0.0.1:8082";
        extraConfig = ''
          auth_basic "stream-api login";
          auth_basic_user_file ${config.sops.secrets.htpasswd.path};
        '';
      };
      locations."/stats/" = {
        proxyPass = "http://127.0.0.1:9999";
        extraConfig = ''
          auth_basic "stream-api login";
          auth_basic_user_file ${config.sops.secrets.htpasswd.path};
        '';
      };
      locations."/stats/srt" = {
        proxyPass = "http://127.0.0.1:8084/streams";
        extraConfig = ''
          auth_basic "stream-api login";
          auth_basic_user_file ${config.sops.secrets.htpasswd.path};
        '';
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    environment.systemPackages = with pkgs; [
      stream-api
    ];
    systemd.services."stream-api" = {
      serviceConfig = {
        ExecStart = "${pkgs.stream-api}/bin/stream-api -config ${streamApiConfigFile}";
      };
      wantedBy = [ "multi-user.target" ];
      restartIfChanged = true;
      restartTriggers = [ streamApiConfigFile ];
    };
  };
}

