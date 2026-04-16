{ config, lib, pkgs, ... }:

{
  security.acme.defaults.email = "voc@c3voc.de";
  security.acme.acceptTerms = true;

  services.nginx = {
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };

  services.cloud-init.settings.ssh_deletekeys = false;

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

  # we don't need LLMNR on a server
  services.resolved.llmnr = "false";
}
