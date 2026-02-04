{ config, lib, pkgs, ... }:

let
  cfg = config.services.taiga;
  inherit (lib) mkEnableOption mkOption mkIf mkDefault types literalExpression concatStringsSep optionalString optionalAttrs optional;

  taigaBackPkg = pkgs.callPackage ../../packages/taiga-back { 
      taigaContribOidcAuth = pkgs.callPackage ../../packages/taiga-contrib-oidc-auth { };
  };
  taigaFrontPkg = pkgs.callPackage ../../packages/taiga-front { };
  taigaEventsPkg = pkgs.callPackage ../../packages/taiga-events { };
  taigaProtectedPkg = pkgs.callPackage ../../packages/taiga-protected { };
  taigaContribOidcAuthFrontend = pkgs.callPackage ../../packages/taiga-contrib-oidc-auth-frontend { };

  oidcUrlsPy = pkgs.writeText "urls.py" ''
    from taiga.urls import *
    urlpatterns += [
        re_path(r"^api/oidc/", include("mozilla_django_oidc.urls")),
    ]
  '';

  oidcBackendPy = pkgs.writeText "oidc_backend.py" ''
    from mozilla_django_oidc.auth import OIDCAuthenticationBackend
    from django.conf import settings

    class TaigaOIDCAuthenticationBackendGroups(OIDCAuthenticationBackend):
        def create_user(self, claims):
            user = super().create_user(claims)
            self._set_permissions(user, claims)
            return user

        def update_user(self, user, claims):
            user = super().update_user(user, claims)
            self._set_permissions(user, claims)
            return user

        def _set_permissions(self, user, claims):
            groups = claims.get("groups", [])
            admin_group = getattr(settings, "OIDC_ADMIN_GROUP", "taiga-admins")
            staff_group = getattr(settings, "OIDC_STAFF_GROUP", "taiga-users")
            user.is_superuser = admin_group in groups
            user.is_staff = staff_group in groups
            user.save()
            return user
  '';

  configPyTemplate = ''
    from .common import *
    import os

    # Override BASE_DIR to point to actual Taiga source
    BASE_DIR = "${taigaBackPkg}/share/taiga-back"

    #############################
    ## GENERAL
    #############################
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.postgresql",
            "NAME": "${cfg.database.name}",
            "USER": "${cfg.database.user}",
            "PASSWORD": "@@DB_PASSWORD@@",
            "HOST": "${cfg.database.host}",
            "PORT": "${toString cfg.database.port}",
        }
    }

    TAIGA_SITES_SCHEME = "https"
    TAIGA_SITES_DOMAIN = "${cfg.domain}"
    FORCE_SCRIPT_NAME = ""
    SECRET_KEY = "@@SECRET_KEY@@"

    TAIGA_URL = f"{ TAIGA_SITES_SCHEME }://{ TAIGA_SITES_DOMAIN }{ FORCE_SCRIPT_NAME }"
    SITES = {
        "api": {"scheme": TAIGA_SITES_SCHEME, "domain": TAIGA_SITES_DOMAIN, "name": "api"},
        "front": {"scheme": TAIGA_SITES_SCHEME, "domain": TAIGA_SITES_DOMAIN, "name": "front"},
    }

    MEDIA_URL = f"{ TAIGA_URL }/media/"
    STATIC_URL = f"{ TAIGA_URL }/static/"
    MEDIA_ROOT = "${cfg.dataDir}/media"
    STATIC_ROOT = "${cfg.dataDir}/static"

    DEFAULT_FILE_STORAGE = "taiga_contrib_protected.storage.ProtectedFileSystemStorage"
    THUMBNAIL_DEFAULT_STORAGE = DEFAULT_FILE_STORAGE

    #############################
    ## SECURITY
    #############################
    DEBUG = False
    PUBLIC_REGISTER_ENABLED = ${if cfg.publicRegisterEnabled then "True" else "False"}

    #############################
    ## CELERY
    #############################
    CELERY_ENABLED = True
    CELERY_BROKER_URL = "amqp://${cfg.rabbitmq.user}:@@RABBITMQ_PASSWORD@@@${cfg.rabbitmq.host}:${toString cfg.rabbitmq.port}/${cfg.rabbitmq.vhost}"
    CELERY_RESULT_BACKEND = None

    #############################
    ## EVENTS
    #############################
    EVENTS_PUSH_BACKEND = "taiga.events.backends.rabbitmq.EventsPushBackend"
    EVENTS_PUSH_BACKEND_OPTIONS = {
        "url": "amqp://${cfg.rabbitmq.user}:@@RABBITMQ_PASSWORD@@@${cfg.rabbitmq.host}:${toString cfg.rabbitmq.port}/${cfg.rabbitmq.vhost}"
    }

    #############################
    ## EMAIL
    #############################
    ${if cfg.email.backend == "smtp" then ''
    EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend"
    EMAIL_HOST = "${cfg.email.host}"
    EMAIL_PORT = ${toString cfg.email.port}
    EMAIL_HOST_USER = "${cfg.email.user}"
    EMAIL_HOST_PASSWORD = "@@EMAIL_PASSWORD@@"
    DEFAULT_FROM_EMAIL = "${cfg.email.defaultFrom}"
    EMAIL_USE_TLS = ${if cfg.email.useTls then "True" else "False"}
    EMAIL_USE_SSL = ${if cfg.email.useSsl then "True" else "False"}
    '' else ''
    EMAIL_BACKEND = "django.core.mail.backends.console.EmailBackend"
    DEFAULT_FROM_EMAIL = "${cfg.email.defaultFrom}"
    ''}

    #############################
    ## TELEMETRY
    #############################
    ENABLE_TELEMETRY = ${if cfg.enableTelemetry then "True" else "False"}

    #############################
    ## ATTACHMENTS
    #############################
    ATTACHMENTS_MAX_AGE = ${toString cfg.attachmentsMaxAge}

    ${optionalString cfg.openidAuth.enable ''
    # OpenID Connect authentication
    INSTALLED_APPS += ["mozilla_django_oidc", "taiga_contrib_oidc_auth",]
    AUTHENTICATION_BACKENDS = list(AUTHENTICATION_BACKENDS) + ["taiga_contrib_oidc_auth.oidc.TaigaOIDCAuthenticationBackend", "settings.oidc_backend.TaigaOIDCAuthenticationBackendGroups",]
    OIDC_ADMIN_GROUP = "infra"
    OIDC_STAFF_GROUP = "voc"
    OIDC_CLAIM_GROUPS_KEY = "groups"
    OIDC_SUPERUSER_GROUP = "infra"
    ROOT_URLCONF = "settings.urls"
    OIDC_CALLBACK_CLASS = "taiga_contrib_oidc_auth.views.TaigaOIDCAuthenticationCallbackView"

    OIDC_BASE_URL="https://sso.c3voc.de"
    OIDC_RP_CLIENT_ID = "${cfg.openidAuth.clientId}"
    OIDC_RP_CLIENT_SECRET = "@@AUTH_SECRET@@"
    OIDC_RP_SCOPES="openid profile email netbox"  # optionally configure scopes
    OIDC_RP_SIGN_ALGO = "RS256"

    OIDC_OP_AUTHORIZATION_ENDPOINT="${cfg.openidAuth.authUrl}"
    OIDC_OP_JWKS_ENDPOINT="https://sso.c3voc.de/application/o/taiga/jwks/"
    OIDC_OP_TOKEN_ENDPOINT="${cfg.openidAuth.tokenUrl}"
    OIDC_OP_USER_ENDPOINT="${cfg.openidAuth.userUrl}"
    ''}
  '';

   frontendConfig = builtins.toJSON ({
    api = "https://${cfg.domain}/api/v1/";
    eventsUrl = "wss://${cfg.domain}/events";
    baseHref = "/";
    debug = false;
    publicRegisterEnabled = cfg.publicRegisterEnabled;
    feedbackEnabled = true;
    supportUrl = "https://community.taiga.io/";
    privacyPolicyUrl = null;
    termsOfServiceUrl = null;
    maxUploadFileSize = null;
    contribPlugins = [];
    enabledImporters = [];
    defaultLoginEnabled = false;
  } // optionalAttrs cfg.openidAuth.enable {
  oidcButtonText = cfg.openidAuth.buttonName;
  oidcMountPoint = "/api/oidc";
  contribPlugins = [ "/plugins/oidc-auth/oidc-auth.json" ];
  } // cfg.frontendExtraConfig);

  eventsEnvTemplate = ''
    RABBITMQ_URL=amqp://${cfg.rabbitmq.user}:@@RABBITMQ_PASSWORD@@@${cfg.rabbitmq.host}:${toString cfg.rabbitmq.port}/${cfg.rabbitmq.vhost}
    SECRET=@@SECRET_KEY@@
    WEB_SOCKET_SERVER_PORT=${toString cfg.eventsPort}
    APP_PORT=${toString cfg.eventsAppPort}
  '';

  substituteSecrets = template: destFile: secretMappings: let
    sedCmds = concatStringsSep " " (lib.mapAttrsToList
      (placeholder: secretFile: ''-e "s|${placeholder}|$(cat ${secretFile})|g"'')
      secretMappings
    );
  in ''
    cat > ${destFile} <<'CONFIGEOF'
    ${template}
    CONFIGEOF
    ${pkgs.gnused}/bin/sed -i ${sedCmds} ${destFile}
    chmod 600 ${destFile}
  '';

in
{
  options.services.taiga = {
    enable = mkEnableOption "Taiga, agile project management platform";

    frontendPackage = mkOption {
      type = types.package;
      default = taigaFrontPkg;
      description = "The Taiga frontend package (set internally).";
    };

    domain = mkOption {
      type = types.str;
      example = "taiga.example.com";
      description = "Domain name where Taiga will be served (subdomain).";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/taiga";
      description = "Directory for Taiga state data (media, static files).";
    };

    user = mkOption {
      type = types.str;
      default = "taiga";
      description = "System user to run Taiga services.";
    };

    group = mkOption {
      type = types.str;
      default = "taiga";
      description = "System group for Taiga services.";
    };

    publicRegisterEnabled = mkOption {
      type = types.bool;
      default = false;
      description = "Allow public user registration.";
    };

    enableTelemetry = mkOption {
      type = types.bool;
      default = false;
      description = "Enable anonymous telemetry.";
    };

    attachmentsMaxAge = mkOption {
      type = types.int;
      default = 360;
      description = "Attachment token expiration in seconds.";
    };

    backendPort = mkOption {
      type = types.port;
      default = 8001;
      description = "Port for the backend gunicorn server.";
    };

    eventsPort = mkOption {
      type = types.port;
      default = 8888;
      description = "Port for the events WebSocket server.";
    };

    eventsAppPort = mkOption {
      type = types.port;
      default = 3023;
      description = "Port for the events app server.";
    };

    protectedPort = mkOption {
      type = types.port;
      default = 8003;
      description = "Port for the protected attachments server.";
    };

    secretKeyFile = mkOption {
      type = types.path;
      description = "Path to file containing the Taiga SECRET_KEY.";
      example = "/run/secrets/taiga/secret-key";
    };

    openidAuth = {
      enable = mkEnableOption "OpenID Connect authentication";

      frontendOidcPackage = mkOption {
        type = types.package;
        default = taigaContribOidcAuthFrontend;
        description = "The Taiga frontend oidc package (set internally).";
      };
      
      userUrl = mkOption {
        type = types.str;
        description = "OpenID Connect userinfo URL";
        example = "https://auth.example.com/realms/main/protocol/openid-connect/userinfo";
      };
      
      tokenUrl = mkOption {
        type = types.str;
        description = "OpenID Connect token URL";
        example = "https://auth.example.com/realms/main/protocol/openid-connect/token";
      };
      
      authUrl = mkOption {
        type = types.str;
        description = "OpenID Connect authorization URL (for frontend)";
        example = "https://auth.example.com/realms/main/protocol/openid-connect/auth";
      };
      
      clientId = mkOption {
        type = types.str;
        description = "OpenID Connect client ID";
      };
      
      clientSecretFile = mkOption {
        type = types.path;
        description = "Path to file containing OpenID Connect client secret";
      };
      
      buttonName = mkOption {
        type = types.str;
        default = "OpenID Connect";
        description = "Name shown on the login button";
      };
    };

    database = {
      host = mkOption {
        type = types.str;
        default = "/run/postgresql";
        description = "PostgreSQL host. Use socket path for local peer auth.";
      };

      port = mkOption {
        type = types.port;
        default = 5432;
        description = "PostgreSQL port.";
      };

      name = mkOption {
        type = types.str;
        default = "taiga";
        description = "PostgreSQL database name.";
      };

      user = mkOption {
        type = types.str;
        default = "taiga";
        description = "PostgreSQL user.";
      };

      passwordFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to file containing the database password. Null for peer auth.";
      };

      createLocally = mkOption {
        type = types.bool;
        default = true;
        description = "Create PostgreSQL database and user locally.";
      };
    };

    rabbitmq = {
      host = mkOption {
        type = types.str;
        default = "localhost";
        description = "RabbitMQ host.";
      };

      port = mkOption {
        type = types.port;
        default = 5672;
        description = "RabbitMQ port.";
      };

      user = mkOption {
        type = types.str;
        default = "taiga";
        description = "RabbitMQ user.";
      };

      passwordFile = mkOption {
        type = types.path;
        description = "Path to file containing the RabbitMQ password.";
        example = "/run/secrets/taiga/rabbitmq-password";
      };

      vhost = mkOption {
        type = types.str;
        default = "taiga";
        description = "RabbitMQ virtual host.";
      };

      createLocally = mkOption {
        type = types.bool;
        default = true;
        description = "Create RabbitMQ vhost and user locally.";
      };
    };

    email = {
      backend = mkOption {
        type = types.enum [ "console" "smtp" ];
        default = "console";
        description = "Email backend: 'console' (stdout) or 'smtp'.";
      };

      host = mkOption {
        type = types.str;
        default = "localhost";
        description = "SMTP server host.";
      };

      port = mkOption {
        type = types.port;
        default = 587;
        description = "SMTP server port.";
      };

      user = mkOption {
        type = types.str;
        default = "";
        description = "SMTP user.";
      };

      passwordFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to file containing the SMTP password.";
      };

      defaultFrom = mkOption {
        type = types.str;
        default = "taiga@${cfg.domain}";
        description = "Default 'From' email address.";
      };

      useTls = mkOption {
        type = types.bool;
        default = true;
        description = "Use TLS for SMTP.";
      };

      useSsl = mkOption {
        type = types.bool;
        default = false;
        description = "Use implicit SSL for SMTP.";
      };
    };

    frontendExtraConfig = mkOption {
      type = types.attrs;
      default = { };
      description = "Extra attributes merged into the frontend conf.json.";
      example = literalExpression ''{ enableSlack = true; }'';
    };
  };

  config = mkIf cfg.enable {

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      createHome = true;
    };
    users.groups.${cfg.group} = { };
    users.users.nginx.extraGroups = [ cfg.group ];

    services.postgresql = mkIf cfg.database.createLocally {
      enable = mkDefault true;
      ensureDatabases = [ cfg.database.name ];
      ensureUsers = [
        {
          name = cfg.database.user;
          ensureDBOwnership = true;
        }
      ];
    };

    services.rabbitmq = mkIf cfg.rabbitmq.createLocally {
      enable = mkDefault true;
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir}             0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.dataDir}/media       0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.dataDir}/static      0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.dataDir}/conf        0750 ${cfg.user} ${cfg.group} -"
      "d /run/taiga                 0750 ${cfg.user} ${cfg.group} -"
    ];

    systemd.services =
    let
      commonServiceConfig = {
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = "${taigaBackPkg}/share/taiga-back";
        StateDirectory = "taiga";
        RuntimeDirectory = "taiga";
        PrivateTmp = true;
        ProtectSystem = "strict";
        ReadWritePaths = [ cfg.dataDir "/run/taiga" ];
        Restart = "on-failure";
        RestartSec = 5;
      };
      commonEnv = {
        DJANGO_SETTINGS_MODULE = "settings.config";
        PYTHONUNBUFFERED = "true";
      };
      secretMappings = {
        "@@SECRET_KEY@@" = cfg.secretKeyFile;
        "@@AUTH_SECRET@@" = cfg.openidAuth.clientSecretFile;
        "@@DB_PASSWORD@@" =
          if cfg.database.passwordFile != null
          then cfg.database.passwordFile
          else "/dev/null";
        "@@RABBITMQ_PASSWORD@@" = cfg.rabbitmq.passwordFile;
      }
      // lib.optionalAttrs (cfg.email.passwordFile != null) {
        "@@EMAIL_PASSWORD@@" = cfg.email.passwordFile;
      };
    in {

      taiga-setup = {
        description = "Taiga initial setup (migrations, collectstatic)";
        after = [ "postgresql.service" "network.target" ];
        requires = optional cfg.database.createLocally "postgresql.service";
        wantedBy = [ "multi-user.target" ];

        serviceConfig = commonServiceConfig // {
          Type = "oneshot";
          RemainAfterExit = true;
          WorkingDirectory = cfg.dataDir;
          ExecStart = "${pkgs.writeShellScript "taiga-setup" ''
            set -euo pipefail

            CONF_DIR="${cfg.dataDir}/conf"
            mkdir -p "$CONF_DIR"
            ${substituteSecrets configPyTemplate "\${CONF_DIR}/config.py" secretMappings}

            ln -sf "$CONF_DIR/config.py" "${taigaBackPkg}/share/taiga-back/settings/config.py" 2>/dev/null || {
              # If the nix store is read-only (it should be), use PYTHONPATH trick
              mkdir -p "$CONF_DIR/settings"
              rm -f "$CONF_DIR/settings/common.py" "$CONF_DIR/settings/__init__.py" "$CONF_DIR/settings/config.py" 2>/dev/null || true
              cp "${taigaBackPkg}/share/taiga-back/settings/common.py" "$CONF_DIR/settings/"
              cp "${taigaBackPkg}/share/taiga-back/settings/__init__.py" "$CONF_DIR/settings/" 2>/dev/null || touch "$CONF_DIR/settings/__init__.py"
              cp "$CONF_DIR/config.py" "$CONF_DIR/settings/config.py"
            }

            ${lib.optionalString cfg.openidAuth.enable ''
              # Copy OIDC urls.py to settings directory
              cp ${oidcUrlsPy} "$CONF_DIR/settings/urls.py"
              cp ${oidcBackendPy} "$CONF_DIR/settings/oidc_backend.py"
              chmod 644 "$CONF_DIR/settings/urls.py"
              chmod 644 "$CONF_DIR/settings/oidc_backend.py"
            ''}
            export DJANGO_SETTINGS_MODULE=settings.config
            export PYTHONPATH="${cfg.dataDir}/conf:${taigaBackPkg}/share/taiga-back"

            ${taigaBackPkg.pythonEnv}/bin/python -m django migrate --noinput

            ${taigaBackPkg.pythonEnv}/bin/python -m django loaddata initial_project_templates 2>/dev/null || true

            ${taigaBackPkg.pythonEnv}/bin/python -m django compilemessages 2>/dev/null || true

            ${taigaBackPkg.pythonEnv}/bin/python -m django collectstatic --noinput

            cat > "${cfg.dataDir}/conf/conf.json" <<'FRONTEOF'
            ${frontendConfig}
            FRONTEOF

            ${substituteSecrets eventsEnvTemplate "\${CONF_DIR}/events.env" secretMappings}
          ''}";
        };
      };

      taiga = {
        description = "Taiga backend (Django/gunicorn)";
        after = [ "taiga-setup.service" "postgresql.service" "rabbitmq.service" "network.target" ];
        requires = [ "taiga-setup.service" ]
          ++ optional cfg.database.createLocally "postgresql.service"
          ++ optional cfg.rabbitmq.createLocally "rabbitmq.service";
        wantedBy = [ "multi-user.target" ];

        environment = commonEnv // {
          PYTHONPATH = "${cfg.dataDir}/conf:${taigaBackPkg}/share/taiga-back";
        };

        serviceConfig = commonServiceConfig // {
          ExecStart = concatStringsSep " " [
            "${taigaBackPkg.pythonEnv}/bin/gunicorn"
            "--workers 4"
            "--timeout 60"
            "--log-level=info"
            "--access-logfile -"
            "--bind 127.0.0.1:${toString cfg.backendPort}"
            "taiga.wsgi"
          ];
        };
      };

      taiga-async = {
        description = "Taiga async tasks (Celery worker + beat)";
        after = [ "taiga-setup.service" "postgresql.service" "rabbitmq.service" "network.target" ];
        requires = [ "taiga-setup.service" ]
          ++ optional cfg.database.createLocally "postgresql.service"
          ++ optional cfg.rabbitmq.createLocally "rabbitmq.service";
        wantedBy = [ "multi-user.target" ];

        environment = commonEnv // {
          DJANGO_SETTINGS_MODULE = "settings.config";
          PYTHONPATH = "${cfg.dataDir}/conf:${taigaBackPkg}/share/taiga-back";
        };

        serviceConfig = commonServiceConfig // {
          WorkingDirectory = cfg.dataDir;
          ExecStart = concatStringsSep " " [
            "${taigaBackPkg.pythonEnv}/bin/celery"
            "-A taiga.celery"
            "worker -B"
            "--concurrency 4"
            "-l INFO"
          ];
          ExecStop = "${pkgs.coreutils}/bin/kill -s TERM $MAINPID";
        };
      };

      taiga-events = {
        description = "Taiga events (WebSocket server)";
        after = [ "taiga-setup.service" "rabbitmq.service" "network.target" ];
        requires = [ "taiga-setup.service" ]
          ++ optional cfg.rabbitmq.createLocally "rabbitmq.service";
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          User = cfg.user;
          Group = cfg.group;
          WorkingDirectory = "${taigaEventsPkg}/lib/taiga-events";
          RuntimeDirectory = "taiga";
          EnvironmentFile = "${cfg.dataDir}/conf/events.env";
          ExecStart = "${taigaEventsPkg}/bin/taiga-events";
          PrivateTmp = true;
          ProtectSystem = "strict";
          ReadWritePaths = [ cfg.dataDir "/run/taiga" ];
          Restart = "on-failure";
          RestartSec = 5;
        };
        path = [ pkgs.bash ];
      };

      taiga-protected = {
        description = "Taiga protected (attachment serving)";
        after = [ "taiga-setup.service" "network.target" ];
        requires = [ "taiga-setup.service" ];
        wantedBy = [ "multi-user.target" ];

        environment = {
          SECRET_KEY = "dummy";
          MAX_AGE = toString cfg.attachmentsMaxAge;
          TAIGA_SUBPATH = "";
        };

        serviceConfig = {
          User = cfg.user;
          Group = cfg.group;
          WorkingDirectory = "${taigaProtectedPkg}/share/taiga-protected";
          RuntimeDirectory = "taiga";
          PrivateTmp = true;
          ProtectSystem = "strict";
          ReadWritePaths = [ cfg.dataDir "/run/taiga" ];
          Restart = "on-failure";
          RestartSec = 5;
          ExecStartPre = "${pkgs.writeShellScript "taiga-protected-env" ''
            # This is a workaround: we read the secret and export it
            # The actual ExecStart inherits the env
          ''}";
          ExecStart = "${pkgs.writeShellScript "taiga-protected-start" ''
            export SECRET_KEY="$(cat ${cfg.secretKeyFile})"
            export MAX_AGE="${toString cfg.attachmentsMaxAge}"
            export TAIGA_SUBPATH=""
            exec ${taigaProtectedPkg}/bin/taiga-protected-gunicorn \
              --workers 4 \
              --timeout 60 \
              --log-level=info \
              --access-logfile - \
              --bind 127.0.0.1:${toString cfg.protectedPort} \
              server:app
          ''}";
        };
      };

      taiga-rabbitmq-init = mkIf cfg.rabbitmq.createLocally {
        description = "Initialize Taiga RabbitMQ vhost and user";
        after = [ "rabbitmq.service" ];
        requires = [ "rabbitmq.service" ];
        wantedBy = [ "multi-user.target" ];
        before = [ "taiga.service" "taiga-async.service" "taiga-events.service" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };

        environment = {
          HOME = "/var/lib/rabbitmq";
        };

        script = ''
          for i in $(seq 1 30); do
            ${pkgs.rabbitmq-server}/bin/rabbitmqctl status >/dev/null 2>&1 && break
            sleep 1
          done

          ${pkgs.rabbitmq-server}/bin/rabbitmqctl add_vhost ${cfg.rabbitmq.vhost} 2>/dev/null || true

          RABBIT_PASS="$(cat ${cfg.rabbitmq.passwordFile})"
          ${pkgs.rabbitmq-server}/bin/rabbitmqctl add_user ${cfg.rabbitmq.user} "$RABBIT_PASS" 2>/dev/null || \
            ${pkgs.rabbitmq-server}/bin/rabbitmqctl change_password ${cfg.rabbitmq.user} "$RABBIT_PASS"

          ${pkgs.rabbitmq-server}/bin/rabbitmqctl set_permissions -p ${cfg.rabbitmq.vhost} ${cfg.rabbitmq.user} ".*" ".*" ".*"
        '';
      };
    };
    environment.systemPackages = let
        createAdminScript = pkgs.writeShellScriptBin "taiga-create-admin" (''
          set -euo pipefail

          export CELERY_ENABLED=False 
          export DJANGO_SETTINGS_MODULE=settings.config
          export PYTHONPATH="${cfg.dataDir}/conf:${taigaBackPkg}/share/taiga-back"

          ${taigaBackPkg.pythonEnv}/bin/python -m django createsuperuser
        '');
      in [ createAdminScript ];   
  };
}
