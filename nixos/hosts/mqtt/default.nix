{
  lib,
  modulesPath,
  pkgs,
  config,
  ...
}:

with lib;

{
  imports = [
    "${modulesPath}/profiles/qemu-guest.nix"
    ./hardware.nix
    ../../profiles/server
    ./mqtt-server.nix
  ];

  system.stateVersion = "25.11"; # do not touch

  networking = {
    nameservers = [ "1.1.1.1" ];
    useDHCP = false;
    defaultGateway = {
      address = "172.31.1.1";
      interface = "enp1s0";
    };
    defaultGateway6 = {
      address = "fe80::1";
      interface = "enp1s0";
    };
    interfaces = {
      enp1s0 = {
        ipv4.addresses = [
          {
            address = "49.13.50.130";
            prefixLength = 32;
          }
        ];
        ipv6.addresses = [
          {
            address = "2a01:4f8:c014:3b7d::1";
            prefixLength = 64;
          }
        ];
      };
    };
  };
}
