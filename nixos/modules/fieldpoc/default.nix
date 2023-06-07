{ config, lib, pkgs, ... }:

with lib;

let cfg = config.services.fieldpoc;
in {
  imports = [
    ./dhcp.nix
  ];

  options = {
    services.fieldpoc = {
      enable = mkEnableOption "fieldpoc";
      ommIp = mkOption {
        type = types.str;
      };
      ommUser = mkOption {
        type = types.str;
      };
      ommPasswordPath = mkOption {
        type = types.path;
      };
      sipsecretPath = mkOption {
        type = types.path;
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      fieldpoc
    ];

    systemd.services.fieldpoc = {
      description = "Simple phone system";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "yate.service" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.fieldpoc}/bin/fieldpoc -c /etc/fieldpoc/config.json -e /etc/fieldpoc/extensions.json --debug";
        ConfigurationDirectory = "fieldpoc";
      };

      preStart = let
        cfgFile = pkgs.writeText "config.json" (lib.generators.toJSON { } {
          controller = {
            host = "127.0.0.1";
            port = 9437;
          };
          dect = {
            host = cfg.ommIp;
            username = cfg.ommUser;
            password = "!!OMMPASSWORD!!";
            sipsecret = "!!SIPSECRET!!";
          };
          yate = {
            host = "127.0.0.1";
            port = 5039;
          };
          database = {
            hostname = "127.0.0.1";
            username = "fieldpoc";
            password = "fieldpoc";
            database = "fieldpoc";
          };
        });
      in ''
        ${pkgs.gnused}/bin/sed -e "s/!!OMMPASSWORD!!/$(cat ${cfg.ommPasswordPath})/g" -e "s/!!SIPSECRET!!/$(cat ${cfg.sipsecretPath})/g" ${cfgFile} > /etc/fieldpoc/config.json
        if [ ! -f "/etc/fieldpoc/extensions.json" ]; then
          echo '{"extensions": {}}' > /etc/fieldpoc/extensions.json
        fi
      '';
    };

    services.postgresql = {
      enable = true;
      initialScript = pkgs.writeText "backend-initScript" ''
        CREATE ROLE fieldpoc WITH LOGIN PASSWORD 'fieldpoc' CREATEDB;
        CREATE DATABASE fieldpoc;
        GRANT ALL PRIVILEGES ON DATABASE fieldpoc TO fieldpoc;
      '';
    };

    services.yate = {
      enable = true;
      config = {
        extmodule."listener ywsd" = {
          type = "tcp";
          addr = "127.0.0.1";
          port = "5039";
        };
        cdrbuild.parameters.X-Eventphone-Id = "false";
        pgsqldb.default = {
          host = "localhost";
          port = "5432";
          database = "fieldpoc";
          user = "fieldpoc";
          password = "fieldpoc";
        };
        register = {
          general = {
            expires = 30;
            "user.auth" = "yes";
            "user.register" = "yes";
            "user.unregister" = "yes";
            "engine.timer" = "yes";
            "call.cdr" = "yes";
            "linetracker" = "yes";
          };
          default = {
            priority = 30;
            account = "default";
          };
          "user.auth" = {
            query = "SELECT password FROM users WHERE username='\${username}' AND password IS NOT NULL AND password<>'' AND type='user' LIMIT 1;";
            result = "password";
          };
          "user.register".query = "INSERT INTO registrations (username, location, oconnection_id, expires) VALUES ('\${username}', '\${data}', '\${oconnection_id}', NOW() + INTERVAL '\${expires} s') ON CONFLICT ON CONSTRAINT uniq_registrations DO UPDATE SET expires = NOW() + INTERVAL '\${expires} s'";
          "user.unregister".query = "DELETE FROM registrations WHERE (username = '\${username}' AND location = '\${data}' AND oconnection_id = '\${connection_id}') OR ('\${username}' = '' AND '\${data}' = '' AND oconnection_id = '\${connection_id}')";
          "engine.timer".query = "DELETE FROM registrations WHERE expires<=CURRENT_TIMESTAMP;";
          "call.cdr".critial = "no";
          "linetracker" = {
            critical = "yes";
            initquery = "UPDATE users SET inuse=0 WHERE inuse is not NULL;DELETE from active_calls;";
            cdr_initialize = "UPDATE users SET inuse=inuse+1 WHERE username='\${external}';INSERT INTO active_calls SELECT username, x_eventphone_id FROM (SELECT '\${external}' as username, '\${X-Eventphone-Id}' as x_eventphone_id, '\${direction}' as direction) as active_call WHERE x_eventphone_id != '' AND x_eventphone_id IS NOT NULL and direction = 'outgoing';";
            cdr_finalize = "UPDATE users SET inuse=(CASE WHEN inuse>0 THEN inuse-1 ELSE 0 END) WHERE username='\${external}';DELETE FROM active_calls WHERE username = '\${external}' AND  x_eventphone_id = '\${X-Eventphone-Id}' AND '\${direction}' = 'outgoing';";
          };
        };
      };
    };
  };
}
