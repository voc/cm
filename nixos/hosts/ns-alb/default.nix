{
  config,
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
    ../../modules/voc-knot
  ];
  config = {
    system.stateVersion = "25.11"; # do not touch
    deployment.tags = [ ];

    services.voc-knot.enable = true;
    services.voc-knot.primary = "ns.bre.c3voc.de";

    networking.hostName = lib.mkOverride 1 "ns";
    networking.domain = "alb.c3voc.de";
  };
}
