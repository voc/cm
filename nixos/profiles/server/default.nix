{ config, lib, pkgs, ... }:

{
  security.acme.defaults.email = "voc@c3voc.de";
  security.acme.acceptTerms = true;

  services.nginx = {
    enable = lib.mkDefault true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };

  services.zfs = lib.mkIf (lib.hasAttrByPath ["zfs"] config.boot.supportedFilesystems) {
    autoScrub.enable = true;
    autoSnapshot = {
      enable = true;
      frequent = 12;
      hourly = 24;
      daily = 3;
      weekly = 0;
      monthly = 0;
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
