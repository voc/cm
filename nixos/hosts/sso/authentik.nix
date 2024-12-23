{ config, lib, pkgs, inputs, ... }:

{
  imports = [ inputs.authentik-nix.nixosModules.default ];

  services.authentik = {
    enable = true;
    environmentFile = "/persist/var/lib/authentik/env";
    nginx = {
      enable = true;
      enableACME = true;
      host = "sso.c3voc.de";
    };
    settings = {
      disable_startup_analytics = true;
      avatars = "attributes.avatar,gravatar,initials";
    };
  };

  services.nginx.virtualHosts."sso.c3voc.de".locations."/outpost.goauthentik.io" = {
    recommendedProxySettings = false;
    extraConfig = ''
      proxy_pass https://localhost:9443/outpost.goauthentik.io;
      proxy_set_header        Host $host;
      proxy_set_header        X-Real-IP $remote_addr;
      proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header        X-Forwarded-Proto $scheme;
    '';
  };

  services.nginx.virtualHosts."authentfix" = {
    listen = [{
      addr = "127.0.0.1";
      port = 8080;
    }];
    locations."/" = {
      recommendedProxySettings = false;
      proxyPass = "https://sso.cccv.de/oauth2/userinfo";
      extraConfig = ''
        sub_filter '"id":' '"sub":';
        sub_filter_types "application/json";
        sub_filter_once on;
      '';
    };
  };
}
