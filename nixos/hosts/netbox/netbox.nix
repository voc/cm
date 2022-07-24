{ config, lib, pkgs, ... }:

{
  services.netbox = {
    enable = true;
    listenAddress = "[::1]";
    secretKeyFile = "/var/lib/netbox/secret";

    extraConfig = ''
      # REMOTE_AUTH_BACKEND = 'social_core.backends.open_id_connect.OpenIdConnectAuth'
      # SOCIAL_AUTH_OIDC_OIDC_ENDPOINT = 'https://auth.c3voc.de'

      EXEMPT_VIEW_PERMISSIONS = ['*']
    '';
  };

  services.nginx.group = "netbox";
  security.acme.certs."netbox.c3voc.de".group = "netbox";
  services.nginx.virtualHosts."netbox.c3voc.de" = {
    forceSSL = true;
    enableACME = true;
    locations."/".proxyPass = "http://localhost:8001";
    locations."/static".root = "${config.services.netbox.dataDir}";
  };
}
