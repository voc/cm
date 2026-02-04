{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf optionalAttrs optionalString;
in

{
  sops = {
    secrets = {
      planka_secret = {
        sopsFile = ./secrets.yaml;
        owner = "planka";
      };
      planka_db_password = {
        sopsFile = ./secrets.yaml;
        owner = "planka";
      };
      planka_db_password_hash = {
        sopsFile = ./secrets.yaml;
      };
      planka_auth_client_id = {
        sopsFile = ./secrets.yaml;
        owner = "planka";
      };
      planka_auth_client_secret = {
        sopsFile = ./secrets.yaml;
        owner = "planka";
      };
      taiga_secret = {
        sopsFile = ./secrets.yaml;
        owner = config.services.taiga.user;
        group = config.services.taiga.group;
      };
      taiga_rabbitmq_password = {
        sopsFile = ./secrets.yaml;
        owner = config.services.taiga.user;
        group = config.services.taiga.group;
      };
      taiga_db_password = {
        sopsFile = ./secrets.yaml;
        owner = config.services.taiga.user;
        group = config.services.taiga.group;
      };
      taiga_db_password_hash = {
        sopsFile = ./secrets.yaml;
      };
      taiga_auth_client_id = {
        sopsFile = ./secrets.yaml;
        owner = config.services.taiga.user;
        group = config.services.taiga.group;
      };
      taiga_auth_client_secret = {
        sopsFile = ./secrets.yaml;
        owner = config.services.taiga.user;
        group = config.services.taiga.group;
      };
      # taiga_email_password = {
      #   sopsFile = ./secrets.yaml;
      #   owner = config.services.taiga.user;
      #   group = config.services.taiga.group;
      # };
    };
  };

  services.planka = {
    enable = true;
    baseUrl = "https://planka.web2.c3voc.de";
    secretKeyFile = config.sops.secrets.planka_secret.path;

    database = {
      createLocally = false;
      host = "127.0.0.1";
      port = 5432;
      name = "planka";
      user = "planka";
      passwordFile = config.sops.secrets.planka_db_password.path;
    };

    oidc = {
      enable = true;
      issuer = "https://sso.c3voc.de/application/o/planka/";
      clientId = config.sops.secrets.planka_auth_client_id.path;
      clientSecretFile = config.sops.secrets.planka_auth_client_secret.path;
      adminRoles = [ "infra" ];
      userRoles = [ "voc" ];
      ownerRoles = [ "infra" ];
      enforced = true;
    };
  };

  services.taiga = {
    enable = true;
    domain = "taiga.web2.c3voc.de";
    secretKeyFile = config.sops.secrets.taiga_secret.path;

    database = {
      createLocally = false;
      host = "127.0.0.1";
      port = 5432;
      name = "taiga";
      user = "taiga";
      passwordFile = config.sops.secrets.taiga_db_password.path;
    };

    rabbitmq = {
      createLocally = true;
      passwordFile = config.sops.secrets.taiga_rabbitmq_password.path;
    };

    openidAuth = {
      enable = true;
      userUrl = "https://sso.c3voc.de/application/o/userinfo/";
      tokenUrl = "https://sso.c3voc.de/application/o/token/";
      authUrl = "https://sso.c3voc.de/application/o/authorize/";
      clientId = "sA3u3Ud1yKjNEwFX5mdw9i2sBiVg67fRX3T8e0YQ";
      clientSecretFile = config.sops.secrets.taiga_auth_client_secret.path;
      buttonName = "Login with SSO";
    };

    # email = {
    #   backend = "smtp";
    #   host = "smtp.example.com";
    #   port = 587;
    #   user = "taiga@example.com";
    #   passwordFile = config.sops.secrets.taiga_email_password.path;
    #   defaultFrom = "taiga@c3voc.de";
    #   useTls = true;
    # };

    enableTelemetry = false;
    publicRegisterEnabled = false;
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "planka" "taiga" ];
    ensureUsers = [{
      name = "planka";
      ensureDBOwnership = true;
    }
    {
      name = "taiga";
      ensureDBOwnership = true;
    }];
    initialScript = pkgs.writeText "init.sql" ''
      GRANT ALL PRIVILEGES ON DATABASE planka TO planka;
      GRANT ALL PRIVILEGES ON DATABASE taiga TO taiga;
      ALTER USER planka WITH PASSWORD '$(cat ${config.sops.secrets.planka_db_password.path})';
      ALTER USER taiga WITH PASSWORD '$(cat ${config.sops.secrets.taiga_db_password.path})';
    '';
    # Set password after first deploy:
    # sudo -u postgres psql -c "ALTER USER planka WITH PASSWORD 'password';"
    # sudo -u postgres psql -c "ALTER USER taiga WITH PASSWORD 'password';"
  };

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "voc@c3voc.de";

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts."planka.web2.c3voc.de" = {
      enableACME = true;
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.planka.port}";
        proxyWebsockets = true;
      };
    };
    
    virtualHosts."taiga.web2.c3voc.de" = {
      enableACME = true;
      forceSSL = true;

      extraConfig = ''
        large_client_header_buffers 4 32k;
        client_max_body_size 50M;
        charset utf-8;
      '';

      locations = {
        "/" = {
          alias = "${config.services.taiga.frontendPackage}/share/taiga-front/";
          index = "index.html";
          tryFiles = "$uri $uri/ /index.html =404";
        };

        "= /conf.json" = {
          alias = "${config.services.taiga.dataDir}/conf/conf.json";
        };

        "/api/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.taiga.backendPort}/api/";
          extraConfig = ''
            proxy_redirect off;
          '';
        };

        "/admin/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.taiga.backendPort}/admin/";
          extraConfig = ''
            proxy_redirect off;
          '';
        };

        "/static/" = {
          alias = "${config.services.taiga.dataDir}/static/";
        };

        "/_protected/" = {
          extraConfig = ''
            internal;
            alias ${config.services.taiga.dataDir}/media/;
            add_header Content-disposition "attachment";
          '';
        };

        "/media/exports/" = {
          alias = "${config.services.taiga.dataDir}/media/exports/";
          extraConfig = ''
            add_header Content-disposition "attachment";
          '';
        };

        "/media/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.taiga.protectedPort}/";
          extraConfig = ''
            proxy_redirect off;
          '';
        };

        "/events" = {
          proxyPass = "http://127.0.0.1:${toString config.services.taiga.eventsPort}/events";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_connect_timeout 7d;
            proxy_send_timeout 7d;
            proxy_read_timeout 7d;
          '';
        };
      } // optionalAttrs config.services.taiga.openidAuth.enable {
        "/plugins/oidc-auth/" = {
          alias = "${config.services.taiga.openidAuth.frontendOidcPackage}/plugins/oidc-auth/";
        };
      };
    };
  };
}
