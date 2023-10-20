{ config, lib, pkgs, ... }:

{
  services.murmur = {
    enable = true;
    logDays = -1;
    welcometext = "The New mng.c3voc.de, now with 100% more config management!";
    sslKey = "/var/lib/acme/mumble.c3voc.de/key.pem";
    sslCert = "/var/lib/acme/mumble.c3voc.de/fullchain.pem";
    bandwidth = 128000;
  };

  networking.firewall.allowedTCPPorts = [ config.services.murmur.port ];
  networking.firewall.allowedUDPPorts = [ config.services.murmur.port ];

  services.nginx.virtualHosts."mumble.c3voc.de" = {
    forceSSL = true;
    enableACME = true;
  };

  # set ACLs so that the murmur user can read the certificates
  security.acme.certs."mumble.c3voc.de".postRun = "${pkgs.acl}/bin/setfacl -Rm u:murmur:rX /var/lib/acme/mumble.c3voc.de";
  security.acme.certs."mumble.c3voc.de".reloadServices = [ "murmur.service" ];
}
