{ config, lib, pkgs, ... }:
{
  imports = [
    ./hardware.nix
    ./loudness-player.nix

    ../../modules/voc2mqtt
  ];

  networking.useDHCP = true;

  networking.domain = "lan.c3voc.de";

  nixpkgs.config.packageOverrides = pkgs: {
    intel-vaapi-driver = pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
  };
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      libvdpau-va-gl
    ];
  };
  environment.sessionVariables = { LIBVA_DRIVER_NAME = "iHD"; };

  system.stateVersion = "25.05";
}

