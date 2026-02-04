{ lib, modulesPath, pkgs, ... }:

with lib;

let
in
{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
    ../../profiles/server
    ../../modules/planka
    ../../modules/taiga
    ./services.nix
  ];
  
  boot.isContainer = true;

  systemd.suppressedSystemUnits = [
    "dev-mqueue.mount"
    "sys-kernel-debug.mount"
    "sys-fs-fuse-connections.mount"
  ];
  system.stateVersion = "25.11";

  networking.hostName = lib.mkOverride 1 "web2";
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  nix.settings.trusted-users = [ "voc" "root" ];
  nix.settings.require-sigs = false;

  services.locate.enable = true;
}
