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
    ../../modules/voc-ingest
  ];
  config = {
    system.stateVersion = "25.11"; # do not touch
    deployment.tags = [ ];

    services.voc-ingest.enable = true;
    services.voc-ingest.relayAuth = true;

    networking.hostName = lib.mkOverride 1 "ingest";
    networking.domain = "alb.c3voc.de";
  };
}
