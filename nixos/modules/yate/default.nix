{ config, lib, pkgs, ... }:

with lib;

let cfg = config.services.yate;
in {
  options = {
    services.yate = {
      enable = mkEnableOption "yate";
      config = mkOption {
        type = with types; attrsOf anything;
        default = { };
      };
    };
  };
  config = let
    mkCfgFile = name: config:
      let
        content =
          if (isString config) then config else generators.toINI { } config;
      in { "yate/${name}.conf".text = content; };
    environmentFiles = mkMerge
      (map (key: mkCfgFile key (getAttr key cfg.config))
        (attrNames cfg.config));
  in mkIf cfg.enable {
    environment.etc = environmentFiles;
    systemd.services.yate = {
      description = "YATE Telephony Server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "postgresql.service" ];

      environment = { PWLIB_ASSERT_ACTION = "C"; };

      serviceConfig = {
        Type = "forking";
        ExecStart =
          "${pkgs.yate}/bin/yate -d -p /run/yate/yate.pid -c /etc/yate -F -s -vvv -DF -r -l /var/lib/yate/yate.log";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        User = "yate";
        Group = "yate";
        AmbientCapabilities = "CAP_NET_BIND_SERVICE";
        RuntimeDirectory = "yate";
        RuntimeDirectoryMode = "0755";
        ConfigurationDirectory = "yate";
        StateDirectory = "yate";
        StateDirectoryMode = "0700";
        PIDFile = "/run/yate/yate.pid";
        TimeoutSec = 30;
      };

      reloadTriggers =
        map (name: config.environment.etc."yate/${name}.conf".source)
        (attrNames cfg.config);
    };

    users.users.yate = {
      isSystemUser = true;
      group = "yate";
    };
    users.groups.yate = { };
  };
}
