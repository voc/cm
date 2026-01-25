{ config, lib, pkgs, ... }:

let
  cfg = config.services.wink;
  
  winkPkg = pkgs.callPackage ../../packages/wink { };
in
{
  options.services.wink = {
    enable = lib.mkEnableOption "Wink inventory management";

    package = lib.mkOption {
      type = lib.types.package;
      default = winkPkg;
      defaultText = lib.literalExpression "pkgs.callPackage ../../packages/wink { }";
      description = "The wink package to use";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Host/IP to bind the Rails server to";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Port to listen on";
    };

    environment = lib.mkOption {
      type = lib.types.enum [ "development" "production" "test" ];
      default = "production";
      description = "Rails environment";
    };

    statePath = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/wink";
      description = "Directory for wink state (database, uploads, etc.)";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "wink";
      description = "User to run wink as";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "wink";
      description = "Group to run wink as";
    };

    workers = lib.mkOption {
      type = lib.types.int;
      default = 2;
      description = "Number of Puma worker processes (0 = single mode)";
    };

    threads = lib.mkOption {
      type = lib.types.str;
      default = "5";
      description = "Puma thread pool size (max)";
    };

    solidQueue = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Solid Queue background job processing";
      };
    };

    extraEnvironment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Additional environment variables for wink";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      default = "wink.c3voc.de";
      description = "Domain name for nginx virtual host";
    };

    enableACME = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable ACME/Let's Encrypt for SSL";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.wink-secret-key-base = {
      owner = cfg.user;
      group = cfg.group;
      mode = "0400";
    };

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.statePath;
      createHome = true;
      description = "Wink service user";
    };
    users.groups.${cfg.group} = { };

    systemd.tmpfiles.rules = [
      "d ${cfg.statePath} 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.statePath}/db 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.statePath}/storage 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.statePath}/tmp 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.statePath}/log 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.statePath}/backups 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.statePath}/app 0750 ${cfg.user} ${cfg.group} -"
    ];

    systemd.services =
      let
        secretKeyBasePath = config.sops.secrets.wink-secret-key-base.path;
        
        commonEnv = {
          RAILS_DISABLE_LOCAL_LOGGING = "1";
          RAILS_ENV = cfg.environment;
          RAILS_LOG_TO_STDOUT = "1";
          RAILS_SERVE_STATIC_FILES = "1";
          DATABASE_PATH = "${cfg.statePath}/storage/production.sqlite3";
          SOLID_QUEUE_DB_PATH = "${cfg.statePath}/storage/production_queue.sqlite3";
          SOLID_CACHE_DB_PATH = "${cfg.statePath}/storage/production_cache.sqlite3";
          SOLID_CABLE_DB_PATH = "${cfg.statePath}/storage/production_cable.sqlite3";
          RAILS_STORAGE_PATH = "${cfg.statePath}/storage";
          WEB_CONCURRENCY = toString cfg.workers;
          RAILS_MAX_THREADS = cfg.threads;
          PORT = toString cfg.port;
          RuntimeDirectoryMode = "0750";
        } // cfg.extraEnvironment;

        commonServiceConfig = {
          User = cfg.user;
          Group = cfg.group;
          WorkingDirectory = "${cfg.package}/share/wink";
          Restart = "on-failure";
          RestartSec = 5;
          StateDirectory = "wink";
          RuntimeDirectory = "wink";
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          NoNewPrivileges = true;
          ReadWritePaths = [ cfg.statePath "/run/wink" ];
          BindPaths = [
            "${cfg.statePath}/storage:${cfg.package}/share/wink/storage"
            "${cfg.statePath}/db:${cfg.package}/share/wink/db"
          ];
        };
      in
      {
        wink = {
          description = "Wink - C3VOC Inventory Management";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];

          environment = commonEnv;
          path = [ cfg.package pkgs.sqlite pkgs.coreutils pkgs.gawk ];

          preStart = ''
            mkdir -p ${cfg.statePath}/storage

            # maybe not needed
            CUR_REL=$(ls -ltd /var/lib/wink/releases/* | head -1 | awk '{print $9}')
            cd $CUR_REL

            export SECRET_KEY_BASE="$(cat ${secretKeyBasePath})"
            ${cfg.package}/bin/wink-rails db:prepare --trace
            ${cfg.package}/bin/wink-rails db:migrate --trace

          '';

          script = ''
            export SECRET_KEY_BASE="$(cat ${secretKeyBasePath})"
            exec ${cfg.package}/bin/wink-server \
              --bind tcp://${cfg.host}:${toString cfg.port}
          '';

          serviceConfig = commonServiceConfig // {
            Type = "simple";
            ExecReload = "${pkgs.coreutils}/bin/kill -USR1 $MAINPID";
          };
        };

        wink-jobs = lib.mkIf cfg.solidQueue.enable {
          description = "Wink - Solid Queue Worker";
          after = [ "network.target" "wink.service" ];
          wantedBy = [ "multi-user.target" ];
          partOf = [ "wink.service" ];

          environment = commonEnv;
          path = [ cfg.package pkgs.sqlite ];

          script = ''
            export SECRET_KEY_BASE="$(cat ${secretKeyBasePath})"
            exec ${cfg.package}/bin/wink-jobs
          '';

          serviceConfig = commonServiceConfig // {
            Type = "simple";
          };
        };

        wink-backup = {
          description = "Backup Wink SQLite databases";
          serviceConfig = {
            Type = "oneshot";
            User = cfg.user;
            Group = cfg.group;
          };
          script = ''
            backup_dir="${cfg.statePath}/backups"
            timestamp=$(date +%Y%m%d-%H%M%S)
            
            if [ -f "${cfg.statePath}/storage/production.sqlite3" ]; then
              ${pkgs.sqlite}/bin/sqlite3 "${cfg.statePath}/storage/production.sqlite3" \
                ".backup '$backup_dir/production-$timestamp.sqlite3'"
            fi
            
            find "$backup_dir" -name "*.sqlite3" -mtime +7 -delete
          '';
        };
      };

    systemd.timers.wink-backup = {
      description = "Daily backup of Wink databases";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };

    services.nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      virtualHosts.${cfg.domain} = {
        forceSSL = cfg.enableACME;
        enableACME = cfg.enableACME;

        locations."/" = {
          proxyPass = "http://${cfg.host}:${toString cfg.port}";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_read_timeout 86400;
          '';
        };

        locations."/assets/" = {
          alias = "${cfg.package}/share/wink/public/assets/";
          extraConfig = ''
            expires max;
            add_header Cache-Control public;
            gzip_static on;
          '';
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}
