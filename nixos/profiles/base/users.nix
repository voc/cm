{ config, lib, pkgs, ... }:

let
  users = builtins.fromTOML (builtins.readFile ../../../users.toml);
  enabled = lib.filterAttrs (name: user: user.enable or false) users;

  enabled_noLib = builtins.filter (x: users.${x}.enable or false) (builtins.attrNames users);
  customConfigs = builtins.filter (x: builtins.pathExists x) (map (name: "${../../users}/${name}/default.nix") enabled_noLib);
in {
  imports = customConfigs;

  users.users = (lib.mapAttrs (name: user: {
    uid = user.uid;
    isNormalUser = true;
    extraGroups = [ "wheel" "systemd-journal" ];
    openssh.authorizedKeys.keys = user.ssh_pubkeys;
  }) enabled) // {
    voc = {
      uid = 1000;
      isNormalUser = true;
      extraGroups = [ "wheel" "systemd-journal" ];
      password = "voc";
      openssh.authorizedKeys.keys = lib.flatten (lib.mapAttrsToList (name: user: user.ssh_pubkeys) enabled);
    };
  };
}
