{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware.nix
    ];

  networking.hostName = "netbox";
  networking.hostId = "329d9704";

  system.stateVersion = "22.05";
}
