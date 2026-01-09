{ config, lib, pkgs, ... }:

with lib;

let cfg = config.services.voc-relay;
in {
  options = {
    services.voc-relay = {
      enable = mkEnableOption "voc-relay";
      isOrigin = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether this node should act as an origin server.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    services.telegraf.extraConfig = {
      enable = true;
      extraConfig = {
        global_tags.role = if cfg.isOrigin then "master-relay" else "edge-relay";
      };
    };
    services.voc-nebula = {
        enable = true;
    };
  };
}
