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
      user = nerd
      password = nerd
      host = 127.0.0.1
      port =
    '';
  in {
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      NERD_CONFIG_FILE = "/etc/nerd/nerd.cfg";
      PYTHONPATH = with pkgs.python310.pkgs; makePythonPath [
        nerd
        psycopg2
      ];
    };

    preStart = ''
      export DJANGO_SECRET=$(cat ${config.sops.secrets.nerd_secret.path})
      ${pkgs.gnused}/bin/sed -e "s/!!DJANGO_SECRET!!/$DJANGO_SECRET/g" ${nerdCfg} > /etc/nerd/nerd.cfg
      ${pkgs.python310.pkgs.nerd}/bin/nerd migrate
    '';

    serviceConfig = {
      User = "nerd";
      Group = "nerd";
      ConfigurationDirectory = "nerd";
      ExecStart = ''
        ${pkgs.python310Packages.gunicorn}/bin/gunicorn \
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
          not remote_ip 127.0.0.1 ::1 185.106.84.27 2001:67c:20a0:e::27
          path /export.json*
        }
        route {
          file_server /static/*
          respond @disallow_export 403 {
            close
          }
          reverse_proxy * http://127.0.0.1:10510
        }
        root * ${pkgs.python310.pkgs.nerd}/var/lib/nerd/
      '';
    };
  };
}
