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
    ../../modules/voc-transcoder
  ];
  config = {
    system.stateVersion = "23.11"; # do not touch
    deployment.tags = [ "transcoders" ];

    networking.hostName = lib.mkOverride 1 "transcoder1";
    networking.domain = "dus.c3voc.de";

    services.voc-transcoder = {
      enable = true;
      name = "transcoder1.dus";
      capacity = 2;
    };
  };
}
