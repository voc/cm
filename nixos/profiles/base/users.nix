{ config, lib, pkgs, ... }:

let
  users = builtins.fromTOML (builtins.readFile ../../../users.toml);
  enabled = lib.filterAttrs (name: user: user.enable_rz or false) users;

  enabled_noLib = builtins.filter (x: users.${x}.enable_rz or false) (builtins.attrNames users);
  customConfigs = builtins.filter (x: builtins.pathExists x) (map (name: "${../../users}/${name}/default.nix") enabled_noLib);
in {
  imports = customConfigs;

  users.mutableUsers = false;
  users.users = (lib.mapAttrs (name: user: {
    uid = user.uid;
    isNormalUser = true;
    extraGroups = [ "wheel" "systemd-journal" ];
    openssh.authorizedKeys.keys = user.ssh_pubkeys;
    hashedPassword = lib.mkIf ((user.password_hash or "") != "") users.password_hash;
  }) enabled) // {
    voc = {
      uid = 1100;
      isNormalUser = true;
      extraGroups = [ "wheel" "systemd-journal" ];
      password = "voc";
      openssh.authorizedKeys.keys = lib.flatten (lib.mapAttrsToList (name: user: user.ssh_pubkeys) enabled);
    };
  };
}
