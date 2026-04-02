{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.voc-transcoder;
in
{
  options = {
    services.voc-transcoder = {
      enable = mkEnableOption "voc-transcoder";
      name = mkOption {
        type = types.str;
        description = "Name to use for stream transcoding.";
      };
      capacity = mkOption {
        type = types.int;
        description = "Max number of concurrent transcodes to run.";
      };
    };
  };

  config = mkIf cfg.enable {
    services.telegraf.extraConfig = {
      global_tags.role = "transcoder";
    };
    services.voc-nebula.enable = true;
    services.voc-consul.enable = true;
    services.stream-transcode = {
      enable = true;
      hostname = cfg.name;
      capacity = cfg.capacity;
    };
    services.upload-proxy.enable = true;
  };
}
