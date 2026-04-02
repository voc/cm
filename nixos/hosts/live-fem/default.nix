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
    deployment.tags = [ "relays" "edge-relays" ];

    boot.loader.grub = {
      enable = true;
      device = "/dev/xvda1";
      extraGrubInstallArgs = ["--target=x86_64-xen"];
    };
    boot.kernelParams = [
      "console=hvc0"
    ];

    networking.hostName = lib.mkOverride 1 "live";
    networking.domain = "fem.c3voc.de";

    networking.useDHCP = false;
    networking.interfaces.enX0.ipv4.addresses = [{
      address = "141.24.220.23";
      prefixLength = 26;
    }];
    networking.interfaces.enX0.ipv6.addresses = [{
      address = "2001:638:904:ffbf::23";
      prefixLength = 64;
    }];
    networking.defaultGateway = "141.24.220.62";
    networking.defaultGateway6 = "2001:638:904:ffbf::1";
    networking.nameservers = [ "1.1.1.1" "1.0.0.1" "2606:4700:4700::1111" "2606:4700:4700::1001" ];

    services.voc-relay = {
      enable = true;
      addressv4 = "193.203.16.36";
      addressv6 = "2a00:c380:c101:2800::36";
    };
  };
}
