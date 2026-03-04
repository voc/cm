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
    ./hardware.nix
    ../../profiles/server
    ../../modules/voc-relay
  ];
  config = {
    system.stateVersion = "25.11"; # do not touch
    deployment.tags = [ "relays" ];

    boot.loader.grub.enable = true;
    boot.loader.grub.device = "/dev/sda";

    networking.hostName = lib.mkOverride 1 "live";
    networking.domain = "nitk.c3voc.de";

    networking.useDHCP = false;
    networking.interfaces.ens18.ipv4.addresses = [{
      address = "78.138.61.80";
      prefixLength = 26;
    }];
    networking.interfaces.ens18.ipv6.addresses = [{
      address = "2a13:ccc3:9:1::80";
      prefixLength = 64;
    }];
    networking.defaultGateway = "78.138.61.65";
    networking.defaultGateway6 = "2a13:ccc3:9:1::1";
    networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];

    services.voc-relay = {
      enable = true;
      isOrigin = true;
      addressv4 = "78.138.61.180";
      addressv6 = "2a13:ccc3:1:7::8";
    };
  };
}
