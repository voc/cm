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
    deployment.tags = [ "relays" ];

    networking.hostName = lib.mkOverride 1 "live";
    networking.domain = "bre.c3voc.de";

    services.voc-relay = {
      enable = true;
      addressv4 = "193.203.16.36";
      addressv6 = "2a00:c380:c101:2800::36";
    };
  };
}
