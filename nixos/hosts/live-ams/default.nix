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
    networking.domain = "ams.c3voc.de";

    services.voc-relay = {
      enable = true;
      addressv4 = "204.2.64.100";
      addressv6 = "2a05:2d01:0:420::100";
    };
  };
}
