{ config, lib, pkgs, ... }:

{
  sops.secrets.nerd_secret = {
    owner = "nerd";
    restartUnits = [ "nerd.service" ];
  };
  systemd.services.nerd = let
    nerdCfg = pkgs.writeText "nerd.cfg" ''
      [django]
      secret = !!DJANGO_SECRET!!
      allowed_hosts = tel.c3voc.de
      debug = False
      language_code = de-de
      time_zone = Europe/Berlin
      csrf_trusted_origins = https://tel.c3voc.de
      [database]
      engine = postgresql_psycopg2
      name = nerd
      user =
      password =
      host = /run/postgresql
      port =
    '';
  in {
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      NERD_CONFIG_FILE = "/etc/nerd/nerd.cfg";
      PYTHONPATH = "${pkgs.python3.pkgs.nerd.pythonPath}:${pkgs.python3.pkgs.nerd}/${pkgs.python3.sitePackages}:${pkgs.python3Packages.psycopg2}/${pkgs.python3.sitePackages}";
    };

    preStart = ''
      export DJANGO_SECRET=$(cat ${config.sops.secrets.nerd_secret.path})
      ${pkgs.gnused}/bin/sed -e "s/!!DJANGO_SECRET!!/$DJANGO_SECRET/g" ${nerdCfg} > /etc/nerd/nerd.cfg
      ${pkgs.python3.pkgs.nerd}/bin/nerd migrate
    '';

    serviceConfig = {
      User = "nerd";
      Group = "nerd";
      ConfigurationDirectory = "nerd";
      ExecStart = ''
        ${pkgs.python3Packages.gunicorn}/bin/gunicorn \
          --bind 0.0.0.0:10510 \
          --access-logfile - \
          nerd.wsgi
      '';
    };
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "nerd" ];
    ensureUsers = [
      {
        name = "nerd";
        ensurePermissions = {
          "DATABASE nerd" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  users.users.nerd = {
    isSystemUser = true;
    group = "nerd";
  };
  users.groups.nerd = {};

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  services.nginx.enable = lib.mkForce false;
  services.caddy = {
    enable = true;
    virtualHosts."tel.c3voc.de" = {
      extraConfig = ''
        @disallow_export {
          not remote_ip 10.42.10.0/24 2a01:4f8:1c0c:8221::/64
          path /export.json*
        }
        route {
          file_server /static/*
          respond @disallow_export 403 {
            close
          }
          reverse_proxy * http://127.0.0.1:10510
        }
        root * ${pkgs.python3.pkgs.nerd}/var/lib/nerd/
      '';
    };
  };
}
