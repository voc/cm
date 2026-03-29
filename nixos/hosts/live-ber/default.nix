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
    networking.domain = "ber.c3voc.de";

    services.voc-relay = {
      enable = true;
      isOrigin = true;
      addressv4 = "185.106.84.40";
      addressv6 = "2001:67c:20a0:e::164";
    };
    system.autoColmena.enable = lib.mkForce false;
  };
}
