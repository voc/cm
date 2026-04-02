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
    };
    services.upload-proxy.enable = true;

    # services.consul-template.instances.nginx = {
    #   settings = {
    #     template = [
    #       {
    #         source = configFile;
    #         destination = "/etc/nginx/voc-relay.conf";
    #         command = "systemctl reload nginx";
    #         left_delimiter = "[[";
    #         right_delimiter = "]]";
    #       }
    #     ];
    #   };
    # };
  };
}
