{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware.nix
      ../../profiles/server
      ./mail.nix
    ];

  networking.hostName = "mail";
  networking.hostId = "4f2a4c63";

  networking.useDHCP = false;
  networking.interfaces.ens18.ipv4.addresses = [{
    address = "185.106.84.29";
    prefixLength = 26;
  }];
  networking.defaultGateway = {
    address = "185.106.84.1";
    interface = "ens18";
  };
  networking.interfaces.ens18.ipv6.addresses = [{
    address = "2001:67c:20a0:e::29";
    prefixLength = 64;
  }];
  networking.defaultGateway6 = {
    address = "2001:67c:20a0:e::1";
    interface = "ens18";
  };
  networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];

  system.stateVersion = "22.11";
}
