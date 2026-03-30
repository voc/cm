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
    deployment.tags = [ "relays" "edge-relays" ];

    networking.hostName = lib.mkOverride 1 "fra1";
    networking.domain = "wob.c3voc.de";

    services.voc-relay = {
      enable = true;
      addressv4 = "62.176.246.6";
      addressv6 = "2a01:581:6::6";
    };
  };
}
