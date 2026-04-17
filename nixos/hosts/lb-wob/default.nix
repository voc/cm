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
    ../../modules/voc-loadbalancer
  ];
  config = {
    system.stateVersion = "25.11"; # do not touch
    deployment.tags = [ "loadbalancers" ];

    networking.hostName = lib.mkOverride 1 "lb";
    networking.domain = "wob.c3voc.de";

    services.voc-loadbalancer = {
      enable = true;
    };
  };
}
