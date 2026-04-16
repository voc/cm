# Copy of upstream nixos module, with adjustments to support loading an externally templated config.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.voc-haproxy;
in
{
  options = {
    services.voc-haproxy = {

      enable = lib.mkEnableOption "HAProxy, the reliable, high performance TCP/HTTP load balancer";

      package = lib.mkPackageOption pkgs "haproxy" { };

      user = lib.mkOption {
        type = lib.types.str;
        default = "haproxy";
        description = "User account under which haproxy runs.";
      };

      group = lib.mkOption {
        type = lib.types.str;
        default = "haproxy";
        description = "Group account under which haproxy runs.";
      };

      configPath = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Path to the HAProxy configuration file.";
      };

      limitNoFile = lib.mkOption {
        type = lib.types.int;
        default = 1024;
        description = "Set file descriptor limit for HAProxy processes.";
      };
    };
  };

  config = lib.mkIf cfg.enable {

    assertions = [
      {
        assertion = cfg.configPath != null;
        message = "You must provide services.voc-haproxy.configPath.";
      }
    ];

    systemd.services.haproxy = {
      description = "HAProxy";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        Type = "notify";
        ExecStartPre = [
          # when the master process receives USR2, it reloads itself using exec(argv[0]),
          # so we create a symlink there and update it before reloading
          "${pkgs.coreutils}/bin/ln -sf ${lib.getExe cfg.package} /run/haproxy/haproxy"
          # when running the config test, don't be quiet so we can see what goes wrong
          "/run/haproxy/haproxy -c -f ${cfg.configPath}"
        ];
        ExecStart = "/run/haproxy/haproxy -Ws -f ${cfg.configPath} -p /run/haproxy/haproxy.pid";
        # support reloading
        ExecReload = [
          "${lib.getExe cfg.package} -c -f ${cfg.configPath}"
          "${pkgs.coreutils}/bin/ln -sf ${lib.getExe cfg.package} /run/haproxy/haproxy"
          "${pkgs.coreutils}/bin/kill -USR2 $MAINPID"
        ];
        KillMode = "mixed";
        SuccessExitStatus = "143";
        Restart = "always";
        RuntimeDirectory = "haproxy";
        LimitNOFILE = cfg.limitNoFile;
        # upstream hardening options
        NoNewPrivileges = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectClock = true;
        RestrictRealtime = true;
        ProtectHostname = true;
        RestrictNamespaces = true;
        ProtectProc = "invisible";
        RestrictAddressFamilies = "AF_INET AF_INET6 AF_UNIX";
        SystemCallFilter = "~@cpu-emulation @keyring @module @obsolete @raw-io @reboot @swap @sync @debug @clock";
        CapabilityBoundingSet = "CAP_NET_BIND_SERVICE";
        # needed in case we bind to port < 1024
        AmbientCapabilities = "CAP_NET_BIND_SERVICE";
      };
    };

    users.users = lib.optionalAttrs (cfg.user == "haproxy") {
      haproxy = {
        group = cfg.group;
        isSystemUser = true;
      };
    };

    users.groups = lib.optionalAttrs (cfg.group == "haproxy") { haproxy = { }; };
  };
}
