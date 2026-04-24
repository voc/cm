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
    "${modulesPath}/virtualisation/proxmox-image.nix"
    ../../profiles/server
    ./monitoring.nix
    ./alerting.nix
    ./alertmanager-mqtt.nix
  ];
  config = {
    system.stateVersion = "25.11"; # do not touch
    networking.hostName = lib.mkOverride 1 "monitoring";
  };
}
