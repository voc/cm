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
    ../../modules/voc-relay
  ];
  config = {
    system.stateVersion = "23.11"; # do not touch

    networking.hostName = lib.mkOverride 1 "live3";
    networking.domain = "alb.c3voc.de";

    services.voc-relay = {
      enable = true;
    };
  };
}
