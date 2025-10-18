{ lib, modulesPath, pkgs, ... }:

with lib;

let
in
{
  imports = [
    "${modulesPath}/virtualisation/proxmox-image.nix"
  ];
  config = {
    system.stateVersion = "23.11"; # do not touch


    networking.useDHCP = false;
    networking.interfaces.eth0.ipv4.addresses = [{
      address = "185.106.84.18";
      prefixLength = 26;
    }];
    networking.interfaces.eth0.ipv6.addresses = [{
      address = "2001:67c:20a0:e::18";
      prefixLength = 64;
    }];
    networking.defaultGateway = "185.106.84.1";
    networking.defaultGateway6 = "2001:67c:20a0:e::1";
    networking.nameservers = [
      "9.9.9.9"
      "1.1.1.1"
    ];

    networking.hostName = lib.mkOverride 1 "forgejo";

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    security.acme.acceptTerms = true;
    security.acme.defaults.email = "voc@c3voc.de";

    services.forgejo.enable = true;
    services.forgejo.settings = { 
      DEFAULT = {
        APP_NAME = "git c3voc";
        APP_SLOGAN = "Versioning your Winkekatze";
      };
      server = {
        ROOT_URL = "https://forgejo.c3voc.de/";
      };
      service = {
        DISABLE_REGISTRATION = true;
      };
      oauth2_client = {
        ENABLE_OPENID_SIGNUP = true;
        REGISTER_EMAIL_CONFIRM = false;
        ENABLE_AUTO_REGISTRATION = true;
        OPENID_CONNECT_SCOPES = "email profile";
        USERNAME = "nickname";
      };
    };
    services.forgejo.database.type = "postgres";

    services.postgresql.enable = true;
    services.postgresql.ensureDatabases = [ "forgejo" ];
    services.postgresql.ensureUsers = [
      {
        name = "forgejo";
        ensureDBOwnership = true;
      }
    ];

    services.nginx.enable = true;
    services.nginx.virtualHosts."forgejo.c3voc.de" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        recommendedProxySettings = true;
        proxyPass = "http://127.0.0.1:3000/";
      };
    };
  };
}
