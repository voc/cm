{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware.nix
    ./disks.nix
    ../../profiles/server
    ../../modules/voc-transcoder
  ];

  deployment.tags = [ "transcoders" ];
  services.voc-transcoder = {
    enable = true;
    name = "daffy.alb";
    capacity = 4;
  };
  # add iHD intel media driver for hardware acceleration
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD (for HD Graphics starting Broadwell (2014) and newer)
    ];
  };

  networking = {
    hostName = lib.mkOverride 1 "daffy";
    domain = "alb.c3voc.de";
    hostId = "0af25e65";
    useDHCP = false;
    bonds = {
      bond0 = {
        interfaces = [
          "eno1"
          "eno2"
        ];
        driverOptions = {
          miimon = "100"; # Monitor MII link every 100ms
          mode = "802.3ad";
          xmit_hash_policy = "layer2";
        };
      };
    };
    vlans = {
      wan = {
        id = 67;
        interface = "bond0";
      };
      lan = {
        id = 69;
        interface = "bond0";
      };
    };
    interfaces.wan.ipv4.addresses = [
      {
        address = "185.106.84.39";
        prefixLength = 26;
      }
    ];
    interfaces.wan.ipv6.addresses = [
      {
        address = "2001:67c:20a0:e::173";
        prefixLength = 64;
      }
    ];
    interfaces.lan.ipv4.addresses = [
      {
        address = "10.73.254.103";
        prefixLength = 24;
      }
    ];
    defaultGateway = "185.106.84.1";
    defaultGateway6 = "2001:67c:20a0:e::1";
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
    ];
  };

  # do not touch
  system.stateVersion = "25.05";
}
