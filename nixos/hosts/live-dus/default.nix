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
    deployment.tags = [ "relays" "origin-relays" ];

    networking.hostName = lib.mkOverride 1 "live";
    networking.domain = "dus.c3voc.de";

    services.voc-relay = {
      enable = true;
      isOrigin = true;
      addressv4 = "46.228.205.55";
      addressv6 = "2001:4ba0:92c1:9f:46:228:205:55";
    };
  };
}
