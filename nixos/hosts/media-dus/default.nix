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
    ../../modules/voc-mirrorbits
  ];
  config = {
    system.stateVersion = "25.11"; # do not touch
    deployment.tags = [ "media-cdn" ];

    boot.loader.grub.enable = true;
    boot.loader.grub.device = "/dev/vda";

    services.voc-mirrorbits.enable = true;

    networking.hostName = lib.mkOverride 1 "duesseldorf";
    networking.domain = "media.ccc.de";

    networking.useDHCP = false;
    networking.interfaces.ens18.ipv4.addresses = [{
      address = "46.228.205.57";
      prefixLength = 28;
    }];
    networking.interfaces.ens18.ipv6.addresses = [{
      address = "2001:4ba0:92c1:9f::57";
      prefixLength = 64;
    }];
    networking.defaultGateway = "46.228.205.49";
    networking.defaultGateway6 = "2001:4ba0:92c1:9f::1";
    networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];
  };
}
