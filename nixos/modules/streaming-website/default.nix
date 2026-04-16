{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.services.streaming-website;
  app = "streaming-website";
  domain = "streaming.media.ccc.de";
  dataDir = "/srv/http/${domain}";
  feedbackDir = "/var/lib/streaming-feedback";
  repo = "https://forgejo.c3voc.de/voc/streaming-website.git";
  branch = "master";
in
{
  options = {
    services.streaming-website = {
      enable = mkEnableOption "streaming-website";
    };
  };

  config = mkIf cfg.enable {
    services.phpfpm.pools.${app} = {
      user = app;
      settings = {
        "listen.owner" = config.services.nginx.user;
        "pm" = "static";
        "pm.max_children" = 20;
        "pm.process_idle_timeout" = "30s";
        "pm.max_requests" = 2048;
        "pm.status_path" = "/stats/php";
        "request_terminate_timeout" = "60s";
        "rlimit_core" = 0;
        "php_admin_value[error_log]" = "stderr";
        "php_admin_value[memory_limit]" = "256M";
        "php_admin_flag[log_errors]" = true;
        "catch_workers_output" = true;
      };
      phpOptions = ''
        expose_php = off
        short_open_tag = on
      '';
      phpEnv."PATH" = lib.makeBinPath [ pkgs.php ];
    };
    systemd.services.phpfpm-streaming-website = {
      serviceConfig = {
        NoNewPrivileges = true;
        ProtectClock = true;
        ProtectHostname = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        ProtectKernelLogs = true;
        RestrictNamespaces = true;
        PrivateTmp = mkForce false; # php-fpm needs access to /tmp for streaming-website
        SystemCallFilter = "@system-service";
      };
    };
    systemd.tmpfiles.rules = [
      "d /var/cache/nginx/streaming_fcgi 0750 nginx nginx" # nginx cache dir
      "d ${feedbackDir} 0750 ${app} ${app}" # feedback data dir
    ];
    services.nginx = {
      enable = true;
      appendHttpConfig = ''
        fastcgi_cache_path /var/cache/nginx/streaming_fcgi
                        levels=1:2 keys_zone=streaming_fcgi:32m inactive=60m;

        map $upstream_http_content_length $flag_cache_empty {
            default 0;
            0       1;
        }

        map $http_x_proto $use_https {
            default off;
            https on;
        }
      '';
      virtualHosts.${domain} = {
        listen = [
          {
            addr = "127.0.0.1";
            port = 8080;
          }
        ];
        root = dataDir;
        extraConfig = ''
          error_page 404 = @404;
          error_page 500 501 502 503 504 = @500;

          location @500 {
              try_files /50x.html =500;
          }

          location @404 {
              try_files /404.php  =404;
          }

          location = /50x.html {
              alias /srv/nginx/htdocs/50x.html;
          }

          location ~* /.*\.(ht|sh|git|htaccess|inc|rb|py|pl|db|sqlite|sqlite3)$ {
              deny  all;
          }

          # serve static files directly add client site caching expire times
          #
          # Example: http://streaming.media.ccc.de/configs/conferences/gpn15/wolkenbar.png
          #          http://streaming.media.ccc.de/assets/js/lib/jquery.min.js
          #
          location ~* (.+\/assets|assets|configs\/conferences).+.(jpg|jpeg|gif|png|ico|ttf|svg|woff.*|swf|mp4|webm|xml|ics|html|json)$ {
              expires 24h;
              add_header Cache-Control "public";
          }

          location ~* (assets|configs\/conferences).+.(js|css|css.map)$ {
              expires 1h;
          }

          location ~* (index|404)\.php$ {
              include ${pkgs.nginx}/conf/fastcgi.conf;

              recursive_error_pages on;
              fastcgi_pass unix:${config.services.phpfpm.pools.${app}.socket};
              fastcgi_index index.php;
              fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
              fastcgi_param HTTPS $use_https;
              fastcgi_keep_conn on;
              # do not cache
              if ($arg_route ~* "feedback\/read") {
              set $do_not_cache 1;
              }
              # caching some php runs
              fastcgi_no_cache $do_not_cache;
              fastcgi_no_cache $flag_cache_empty;
              fastcgi_cache_bypass $do_not_cache;
              fastcgi_cache_bypass $flag_cache_empty;
              fastcgi_cache_key "$request_method$http_x_proto$uri$is_args$args";
              fastcgi_cache streaming_fcgi;
              fastcgi_cache_valid 200 5m;
              fastcgi_cache_methods GET;
              add_header X-Cache "$upstream_cache_status origin";
              add_header Access-Control-Allow-Origin "*";
          }

          location / {
              rewrite /(.*) /index.php?route=$1 last;
          }
        '';
      };
    };
    users.users.${app} = {
      isSystemUser = true;
      home = dataDir;
      group = app;
    };
    users.groups.${app} = { };
    sops.secrets = {
      feedback_password = {
        sopsFile = ./secrets.yaml;
        key = "feedback/password";
      };
    };
    systemd.services.update-streaming-website = {
      serviceConfig.Type = "oneshot";
      path = with pkgs; [
        bash
        git
        sudo
        php
      ];
      script = ''
        # setup streaming-feedback password
        cp ${config.sops.secrets.feedback_password.path} ${feedbackDir}/password
        chown root:${app} ${feedbackDir}/password
        chmod 640 ${feedbackDir}/password

        # initial clone
        if [ ! -d ${dataDir} ]; then
          git clone ${repo} ${dataDir};
          chown -R ${app}:${app} ${dataDir};
        else
          echo "updating code"
          cd ${dataDir}
          sudo -u ${app} ${pkgs.writeShellScript "update.sh" ''
            echo "updating to latest version on ${branch}"
            git fetch origin
            git reset --hard HEAD
            git checkout ${branch}
            git reset --hard origin/${branch}

            echo "re-downloading schedules"
            php index.php download
          ''}
        fi
        echo "clearing caches"
        rm -rf /var/cache/nginx/streaming_fcgi/*
      '';
      wantedBy = [ "multi-user.target" ];
    };
    systemd.services.update-schedule = {
      serviceConfig.Type = "oneshot";
      serviceConfig.WorkingDirectory = dataDir;
      serviceConfig.User = app;
      path = with pkgs; [
        bash
        php
      ];
      script = ''
        echo "downloading schedules"
        php index.php download
      '';
    };
    systemd.timers.update-schedule = {
      wantedBy = [ "timers.target" ];
      partOf = [ "update-schedule.service" ];
      description = "Download event schedules every 15 minutes";
      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = "15m";
      };
    };
    systemd.services.mqttfeedback =
      let
        pythonEnv = pkgs.python3.withPackages (ps: with ps; [ aiomqtt ]);
      in
      {
        serviceConfig.WorkingDirectory = feedbackDir;
        serviceConfig.User = app;
        serviceConfig.ExecStartPre = pkgs.writeShellScript "init-db.sh" ''
          # initialize feedback db if necessary
          if [ ! -f ${feedbackDir}/feedback.sqlite3 ]; then
            echo "initializing feedback database"
            ${pkgs.sqlite}/bin/sqlite3 ${feedbackDir}/feedback.sqlite3 < ${dataDir}/lib/feedback/schema.sql
          fi'';
        path = [ pythonEnv ];
        script = ''
          set -euo pipefail
          # reuse voc2mqtt credentials
          export MQTT_USER=$(< ${config.sops.secrets.mqtt_username.path})
          export MQTT_PASSWORD=$(< ${config.sops.secrets.mqtt_password.path})
          export MQTT_SERVER=mqtt.c3voc.de

          python ${./mqttfeedback.py} -f feedback.sqlite3
        '';
        after = [ "update-streaming-website.service" ];
        wantedBy = [ "multi-user.target" ];
      };
  };
}
