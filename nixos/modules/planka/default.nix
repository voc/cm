{ config, lib, pkgs, ... }:

let
  cfg = config.services.planka;
  inherit (lib) mkEnableOption mkOption mkIf types optionalString;

  plankaPkg = pkgs.callPackage ../../packages/planka { };
in
{
  options.services.planka = {
    enable = mkEnableOption "Planka kanban board";

    package = mkOption {
      type = types.package;
      default = plankaPkg;
      description = "The Planka package to use.";
    };

    baseUrl = mkOption {
      type = types.str;
      example = "https://planka.example.com";
      description = "Public URL where Planka will be accessible.";
    };

    port = mkOption {
      type = types.port;
      default = 1337;
      description = "Port to listen on.";
    };

    address = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Address to bind to.";
    };

    secretKeyFile = mkOption {
      type = types.path;
      description = "Path to secret key file. Generate with: openssl rand -hex 64";
    };

    trustProxy = mkOption {
      type = types.bool;
      default = true;
      description = "Trust X-Forwarded-* headers from reverse proxy.";
    };

    tokenExpiresIn = mkOption {
      type = types.nullOr types.int;
      default = 365;
      description = "Auth token expiration in days.";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/planka";
      description = "Directory for attachments and state.";
    };

    user = mkOption {
      type = types.str;
      default = "planka";
      description = "Service user.";
    };

    group = mkOption {
      type = types.str;
      default = "planka";
      description = "Service group.";
    };

    extraEnv = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Additional environment variables.";
    };

    database = {
      createLocally = mkOption {
        type = types.bool;
        default = true;
        description = "Create local PostgreSQL database.";
      };

      host = mkOption {
        type = types.str;
        default = "/run/postgresql";
        description = "Database host or socket path.";
      };

      port = mkOption {
        type = types.port;
        default = 5432;
        description = "Database port.";
      };

      name = mkOption {
        type = types.str;
        default = "planka";
        description = "Database name.";
      };

      user = mkOption {
        type = types.str;
        default = "planka";
        description = "Database user.";
      };

      passwordFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Database password file (not needed for local socket auth).";
      };
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open firewall for Planka port.";
    };

    oidc = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable OIDC authentication.";
      };

      issuer = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "OIDC issuer URL.";
      };

      clientId = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "OIDC client ID.";
      };

      clientSecretFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to OIDC client secret file.";
      };

      scopes = mkOption {
        type = types.str;
        default = "openid email profile";
        description = "OIDC scopes.";
      };

      adminRoles = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Roles granting admin access.";
      };

      userRoles = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Roles granting user access.";
      };

      ownerRoles = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Roles granting project owner access.";
      };

      rolesAttribute = mkOption {
        type = types.str;
        default = "groups";
        description = "Claim containing user roles.";
      };

      enforced = mkOption {
        type = types.bool;
        default = false;
        description = "Disable local auth, require OIDC.";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = cfg.oidc.enable -> (cfg.oidc.issuer != null && cfg.oidc.clientId != null);
      message = "OIDC requires issuer and clientId.";
    }];

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      createHome = true;
    };

    users.groups.${cfg.group} = { };

    services.postgresql = mkIf cfg.database.createLocally {
      enable = true;
      ensureDatabases = [ cfg.database.name ];
      ensureUsers = [{
        name = cfg.database.user;
        ensureDBOwnership = true;
      }];
    };

    systemd.services.planka-setup = {
      description = "Setup Planka Application Directory";
      after = [ "network.target" ];
      
      path = [ pkgs.coreutils pkgs.bash ];

      script = ''
        mkdir -p "${cfg.dataDir}/attachments"
        mkdir -p "${cfg.dataDir}/user-avatars"
        mkdir -p "${cfg.dataDir}/project-background-images"
        mkdir -p "${cfg.dataDir}/logs"

        rm -rf /var/lib/planka/app
        cp -r ${cfg.package}/lib/planka /var/lib/planka/app
        chmod -R u+w /var/lib/planka/app

        rm -rf /var/lib/planka/app/private/attachments
        ln -sf "${cfg.dataDir}/attachments" /var/lib/planka/app/private/attachments

        rm -rf /var/lib/planka/app/logs
        ln -sf "${cfg.dataDir}/logs" /var/lib/planka/app/logs

        if [ -d /var/lib/planka/app/public/user-avatars ]; then
          rm -rf /var/lib/planka/app/public/user-avatars
          ln -sf "${cfg.dataDir}/user-avatars" /var/lib/planka/app/public/user-avatars
        fi
        if [ -d /var/lib/planka/app/public/project-background-images ]; then
          rm -rf /var/lib/planka/app/public/project-background-images
          ln -sf "${cfg.dataDir}/project-background-images" /var/lib/planka/app/public/project-background-images
        fi
      '';

      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.group;
        StateDirectory = "planka";
        StateDirectoryMode = "0750";
        RemainAfterExit = true;
        ReadWritePaths = [ cfg.dataDir "/var/lib/planka" ];
        ProtectSystem = "strict";
      };
    };

    systemd.services.planka = {
      description = "Planka Kanban Board";
      after = [ "network.target" "planka-setup.service" ] ++ lib.optional cfg.database.createLocally "postgresql.service";
      wants = [ "planka-setup.service" ] ++ lib.optional cfg.database.createLocally "postgresql.service";
      requires = [ "planka-setup.service" ];
      wantedBy = [ "multi-user.target" ];

      path = [ cfg.package.nodejs pkgs.openssl pkgs.coreutils pkgs.bash ];

      environment = {
        NODE_ENV = "production";
        PORT = toString cfg.port;
        HOST = cfg.address;
        BASE_URL = cfg.baseUrl;
        TRUST_PROXY = if cfg.trustProxy then "true" else "false";
        DEFAULT_LANGUAGE= "en-US";
        ATTACHMENTS_PATH = "${cfg.dataDir}/attachments";
      } // lib.optionalAttrs (cfg.tokenExpiresIn != null) {
        TOKEN_EXPIRES_IN = toString cfg.tokenExpiresIn;
      } // lib.optionalAttrs cfg.oidc.enable {
        OIDC_ISSUER = cfg.oidc.issuer;
        OIDC_CLIENT_ID = cfg.oidc.clientId;
        OIDC_SCOPES = cfg.oidc.scopes;
        OIDC_ROLES_ATTRIBUTE = cfg.oidc.rolesAttribute;
      } // lib.optionalAttrs (cfg.oidc.enable && cfg.oidc.adminRoles != [ ]) {
        OIDC_ADMIN_ROLES = lib.concatStringsSep "," cfg.oidc.adminRoles;
      } // lib.optionalAttrs (cfg.oidc.enable && cfg.oidc.userRoles != [ ]) {
        OIDC_BOARD_USER_ROLES = lib.concatStringsSep "," cfg.oidc.userRoles;
      } // lib.optionalAttrs (cfg.oidc.enable && cfg.oidc.userRoles != [ ]) {
        OIDC_PROJECT_OWNER_ROLES = lib.concatStringsSep "," cfg.oidc.ownerRoles;
      } // lib.optionalAttrs (cfg.oidc.enable && cfg.oidc.enforced) {
        OIDC_ENFORCED = "true";
      } // cfg.extraEnv;

      script = let
        dbUrl =
          if cfg.database.createLocally then
            "postgresql:///?host=/run/postgresql&dbname=${cfg.database.name}&user=${cfg.database.user}"
          else if cfg.database.passwordFile != null then
            "postgresql://${cfg.database.user}:$(cat ${cfg.database.passwordFile})@${cfg.database.host}:${toString cfg.database.port}/${cfg.database.name}"
          else
            "postgresql://${cfg.database.user}@${cfg.database.host}:${toString cfg.database.port}/${cfg.database.name}";
      in ''
        export SECRET_KEY="$(cat ${cfg.secretKeyFile})"
        export DATABASE_URL="${dbUrl}"
        ${optionalString (cfg.oidc.enable && cfg.oidc.clientSecretFile != null) ''
          export OIDC_CLIENT_SECRET="$(cat ${cfg.oidc.clientSecretFile})"
        ''}
        ${optionalString (cfg.oidc.enable && cfg.oidc.clientId != null) ''
          export OIDC_CLIENT_ID="$(cat ${cfg.oidc.clientId})"
        ''}
        cd /var/lib/planka/app
        exec node app.js
      '';

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = "/var/lib/planka/app";
        Restart = "on-failure";
        RestartSec = "5s";

        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ cfg.dataDir "/var/lib/planka" ];
        CapabilityBoundingSet = "";
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        MemoryDenyWriteExecute = false;
        LockPersonality = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
        SystemCallArchitectures = "native";
      };
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    systemd.services.planka-db-init = {
      description = "Initialize Planka Database";
      after = [ "network.target" "planka-setup.service" ] ++ lib.optional cfg.database.createLocally "postgresql.service";
      wants = lib.optional cfg.database.createLocally "postgresql.service";
      requires = [ "planka-setup.service" ];
      
      path = [ cfg.package.nodejs pkgs.openssl pkgs.bash pkgs.coreutils ];

      environment = {
        NODE_ENV = "production";
        BASE_URL = cfg.baseUrl;
      };

      script = let
        dbUrl =
          if cfg.database.createLocally then
            "postgresql:///?host=/run/postgresql&dbname=${cfg.database.name}&user=${cfg.database.user}"
          else if cfg.database.passwordFile != null then
            "postgresql://${cfg.database.user}:$(cat ${cfg.database.passwordFile})@${cfg.database.host}:${toString cfg.database.port}/${cfg.database.name}"
          else
            "postgresql://${cfg.database.user}@${cfg.database.host}:${toString cfg.database.port}/${cfg.database.name}";
      in ''
        export SECRET_KEY="$(cat ${cfg.secretKeyFile})"
        export DATABASE_URL="${dbUrl}"
        cd /var/lib/planka/app
        exec npm run db:init
      '';

      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = "/var/lib/planka/app";
        RemainAfterExit = false;
        ReadWritePaths = [ cfg.dataDir "/var/lib/planka" ];
        ProtectSystem = "strict";
      };
    };

    systemd.services.planka-db-migrate = {
      description = "Migrate Planka Database";
      after = [ "network.target" "planka-setup.service" ] ++ lib.optional cfg.database.createLocally "postgresql.service";
      wants = lib.optional cfg.database.createLocally "postgresql.service";
      requires = [ "planka-setup.service" ];
      
      path = [ cfg.package.nodejs pkgs.openssl pkgs.bash pkgs.coreutils ];

      environment = {
        NODE_ENV = "production";
        BASE_URL = cfg.baseUrl;
      };

      script = let
        dbUrl =
          if cfg.database.createLocally then
            "postgresql:///?host=/run/postgresql&dbname=${cfg.database.name}&user=${cfg.database.user}"
          else if cfg.database.passwordFile != null then
            "postgresql://${cfg.database.user}:$(cat ${cfg.database.passwordFile})@${cfg.database.host}:${toString cfg.database.port}/${cfg.database.name}"
          else
            "postgresql://${cfg.database.user}@${cfg.database.host}:${toString cfg.database.port}/${cfg.database.name}";
      in ''
        export SECRET_KEY="$(cat ${cfg.secretKeyFile})"
        export DATABASE_URL="${dbUrl}"
        cd /var/lib/planka/app
        exec npm run db:migrate
      '';

      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = "/var/lib/planka/app";
        RemainAfterExit = false;
        ReadWritePaths = [ cfg.dataDir "/var/lib/planka" ];
        ProtectSystem = "strict";
      };
    };

    systemd.services.planka-db-upgrade = {
      description = "Upgrade Planka Database";
      after = [ "network.target" "planka-setup.service" ] ++ lib.optional cfg.database.createLocally "postgresql.service";
      wants = lib.optional cfg.database.createLocally "postgresql.service";
      requires = [ "planka-setup.service" ];
      
      path = [ cfg.package.nodejs pkgs.openssl pkgs.bash pkgs.coreutils ];

      environment = {
        NODE_ENV = "production";
        BASE_URL = cfg.baseUrl;
      };

      script = let
        dbUrl =
          if cfg.database.createLocally then
            "postgresql:///?host=/run/postgresql&dbname=${cfg.database.name}&user=${cfg.database.user}"
          else if cfg.database.passwordFile != null then
            "postgresql://${cfg.database.user}:$(cat ${cfg.database.passwordFile})@${cfg.database.host}:${toString cfg.database.port}/${cfg.database.name}"
          else
            "postgresql://${cfg.database.user}@${cfg.database.host}:${toString cfg.database.port}/${cfg.database.name}";
      in ''
        export SECRET_KEY="$(cat ${cfg.secretKeyFile})"
        export DATABASE_URL="${dbUrl}"
        cd /var/lib/planka/app
        exec npm run db:upgrade
      '';

      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = "/var/lib/planka/app";
        RemainAfterExit = false;
        ReadWritePaths = [ cfg.dataDir "/var/lib/planka" ];
        ProtectSystem = "strict";
      };
    };

    environment.systemPackages = let
      createAdminScript = pkgs.writeShellScriptBin "planka-create-admin" (''
        set -euo pipefail
        
        # Check for required env vars, prompt if not set
        if [ -z "''${DEFAULT_ADMIN_EMAIL:-}" ]; then
          read -p "Admin email: " DEFAULT_ADMIN_EMAIL
          export DEFAULT_ADMIN_EMAIL
        fi
        if [ -z "''${DEFAULT_ADMIN_PASSWORD:-}" ]; then
          read -s -p "Admin password: " DEFAULT_ADMIN_PASSWORD
          echo
          export DEFAULT_ADMIN_PASSWORD
        fi
        if [ -z "''${DEFAULT_ADMIN_NAME:-}" ]; then
          read -p "Admin name: " DEFAULT_ADMIN_NAME
          export DEFAULT_ADMIN_NAME
        fi
        if [ -z "''${DEFAULT_ADMIN_USERNAME:-}" ]; then
          read -p "Admin username: " DEFAULT_ADMIN_USERNAME
          export DEFAULT_ADMIN_USERNAME
        fi
        
        export SECRET_KEY="$(cat ${cfg.secretKeyFile})"
      '' + (if cfg.database.createLocally then ''
        export DATABASE_URL="postgresql:///?host=/run/postgresql&dbname=${cfg.database.name}&user=${cfg.database.user}"
      '' else if cfg.database.passwordFile != null then ''
        export DATABASE_URL="postgresql://${cfg.database.user}:$(cat ${cfg.database.passwordFile})@${cfg.database.host}:${toString cfg.database.port}/${cfg.database.name}"
      '' else ''
        export DATABASE_URL="postgresql://${cfg.database.user}@${cfg.database.host}:${toString cfg.database.port}/${cfg.database.name}"
      '') + ''
        export NODE_ENV="production"
        export BASE_URL="${cfg.baseUrl}"
        export PATH="${cfg.package.nodejs}/bin:${pkgs.bash}/bin:''$PATH"
        cd /var/lib/planka/app
        exec npm run db:seed
      '');
    in [ createAdminScript ];
  };
}
