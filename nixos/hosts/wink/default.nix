{ config, lib, pkgs, ... }:

{

  imports =
    [ # Include the results of the hardware scan.
      ./hardware.nix
      ../../profiles/server
      ./wink.nix
    ];

  networking.hostName = "wink";

  networking.useDHCP = false;
  networking.interfaces.eth0.ipv4.addresses = [{
    address = "185.106.84.55";
    prefixLength = 26;
  }];
  networking.interfaces.eth0.ipv6.addresses = [{
    address = "2001:67c:20a0:e::184";
    prefixLength = 64;
  }];
  networking.defaultGateway = "185.106.84.1";
  networking.defaultGateway6 = "2001:67c:20a0:e::1";
  networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];

  system.stateVersion = "25.05";
}
