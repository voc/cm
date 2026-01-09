{
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
    ../../modules/voc-relay
  ];
  config = {
    system.stateVersion = "23.11"; # do not touch

    networking.hostName = lib.mkOverride 1 "live3";
    networking.domain = "alb.c3voc.de";

    services.voc-relay = {
      enable = true;
    };

    # networking.firewall.allowedTCPPorts = [
    #   80
    #   443
    # ];

    # security.acme.acceptTerms = true;
    # security.acme.defaults.email = "voc@c3voc.de";

    # services.nginx.enable = true;
    # services.nginx.virtualHosts."forgejo.c3voc.de" = {
    #   forceSSL = true;
    #   enableACME = true;
    #   locations."/" = {
    #     recommendedProxySettings = true;
    #     proxyPass = "http://127.0.0.1:3000/";
    #   };
    # };
  };
}
