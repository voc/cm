{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware.nix
      ../../profiles/server
      ./jira.nix
    ];

  networking.hostName = "jira";
  networking.hostId = "0ad6635f";
  environment.etc.machine-id.text = "98458ce598ec49768d86b8758d7edbde";

  networking.useDHCP = false;
  networking.interfaces.ens18.ipv4.addresses = [{
    address = "31.172.33.107";
    prefixLength = 28;
  }];
  networking.defaultGateway = {
    address = "31.172.33.110";
    interface = "ens18";
  };
  networking.interfaces.ens18.ipv6.addresses = [{
    address = "2a01:a700:48d1::107";
    prefixLength = 64;
  }];
  networking.defaultGateway6 = {
    address = "2a01:a700:48d1::1";
    interface = "ens18";
  };
  networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];

  system.stateVersion = "23.05";
}
