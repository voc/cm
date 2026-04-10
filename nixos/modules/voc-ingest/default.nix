{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.voc-ingest;
  hostFqdn = "${config.networking.hostName}.${config.networking.domain}";
  statsXsl = pkgs.writeTextFile {name = "stat.xsl"; text = (builtins.readFile ./stat.xsl); destination = "/public/stat.xsl"; };
  streamApiConfigFile = pkgs.writeText "config.yml" ''
    publisher:
      enable: yes
      sources:
        - type: icecast
          url: http://localhost:8000
        - type: srtrelay
          url: http://localhost:8084
  '';

in
{
  options = {
    services.voc-ingest = {
      enable = mkEnableOption "voc-ingest";
      relayAuth = mkOption {
        type = types.bool;
        default = true;
        description = "Require RTMP auth via /backend to publish to /relay";
      };
      acmeExtraSANs = mkOption {
        type = with types; listOf str;
        default = [ ];
        example = [ "ingest2.c3voc.de" "relay.c3voc.de" ];
        description = "Additional SAN for the certificate for the NGINX config";
      };
    };
  };

  config = mkIf cfg.enable {
    # enable nebula
    services.voc-nebula.enable = true;
    # enable consul
    services.voc-consul.enable = true;

    services.telegraf.extraConfig = {
      global_tags.role = "ingest";
    };

    services.srtrelay.enable = true;
    services.rtmp-auth.enable = true;

    sops.templates."icecast.xml".owner = "nobody";
    sops.templates."icecast.xml".content = ''
      <icecast>
          <hostname>${config.networking.hostName}.${config.networking.domain}</hostname>
          <location>voc</location>
          <admin>contact@c3voc.de</admin>
          <server-id>Icecast 2</server-id>

          <limits>
              <clients>4096</clients>
              <sources>500</sources>
              <threadpool>10</threadpool>
              <queue-size>4055040</queue-size>
              <client-timeout>30</client-timeout>
              <header-timeout>15</header-timeout>
              <source-timeout>10</source-timeout>

              <burst-on-connect>0</burst-on-connect>
              <burst-size>524280</burst-size>
          </limits>

          <authentication>
              <source-password>${config.sops.placeholder.icecastSourcePassword}</source-password>
              <relay-password>${config.sops.placeholder.icecastRelayPassword}</relay-password>

              <admin-user>admin</admin-user>
              <admin-password>${config.sops.placeholder.icecastAdminPassword}</admin-password>
          </authentication>

          <listen-socket>
              <port>8000</port>
              <bind-address>::</bind-address>
              <bindv6only>0</bindv6only>
          </listen-socket>


          <!-- additional mount points with separate authentication -->

          <!-- This flag turns on the icecast2 fileserver from which static files can be served. -->
          <fileserve>1</fileserve>
          <paths>
              <basedir>/usr/local/share/icecast</basedir>

              <logdir>/var/log/icecast</logdir>
              <webroot>${pkgs.icecast}/share/icecast/web</webroot>
              <adminroot>${pkgs.icecast}/share/icecast/admin</adminroot>

              <alias source="/" destination="/status.xsl"/>
          </paths>

          <logging>
            <errorlog>error.log</errorlog>

            <loglevel>3</loglevel> <!-- 4 Debug, 3 Info, 2 Warn, 1 Error -->
            <logsize>1000</logsize>  <!-- Max size of a logfile -->
          </logging>

          <security>
              <chroot>0</chroot>
              <changeowner>
                  <user>nobody</user>
                  <group>nogroup</group>
              </changeowner>
          </security>
      </icecast>
    '';
    sops.templates."nginx-rtmp.conf".owner = "nginx";
    sops.templates."nginx-rtmp.conf".content = ''
      rtmp_auto_push off;
      rtmp {
        log_format rtmp '"$remote_addr [$time_local] $command "$app" "$name" "$args" - $bytes_received $bytes_sent ($session_readable_time)"';
        access_log /var/log/nginx/rtmp_access.log rtmp;

        server {
          listen [::]:1935 ipv6only=off;

          ping 30s;

          # Disable audio until first video frame is sent.
          wait_video on;
          # Send NetStream.Publish.Start and NetStream.Publish.Stop to subscribers.
          publish_notify on;

          # Synchronize audio and video streams. If subscriber bandwidth is not
          # enough to receive data at publisher rate some frames are dropped by
          # the server. This leads to synchronization problem. When timestamp
          # difference exceeds the value specified as sync argument an absolute
          # frame is sent fixing that. Default is 300ms.
          sync 10ms;

          # stream with forward to icecast
          application stream {
            # enable live streaming
            live on;

            # copy breaks relaying, on pollutes downstream
            meta off;

            allow publish all;
            allow play all;

            # authenticate stream publish against backend
            on_publish http://127.0.0.1:8080/publish;
            on_publish_done http://127.0.0.1:8080/unpublish;

            # drop idle streams
            drop_idle_publisher 10s;
            idle_streams off;

            # forward streams to local icecast
            exec ${pkgs.ffmpeg}/bin/ffmpeg -v warning -nostats -nostdin -y -analyzeduration 1000000
              -f live_flv -i rtmp://127.0.0.1/$app/$name
              -c copy -map 0:v:0 -map 0:a:0
              -f matroska -content_type video/webm -password ${config.sops.placeholder.icecastSourcePassword}
              icecast://127.0.0.1:8000/$name;
          }

          # relay only
          application relay {
            live on;
            meta off;

            allow publish all;
            allow play all;

            ${optionalString cfg.relayAuth ''
            # authenticate stream publish against backend
            on_publish http://127.0.0.1:8080/publish;
            on_publish_done http://127.0.0.1:8080/unpublish;
            ''}

            # drop idle streams
            drop_idle_publisher 10s;
            idle_streams off;
          }
        }
      }
    '';

    sops.secrets = {
      htpasswd = {
        sopsFile = ./secrets.yaml;
        key = "htpasswd";
        owner = "nginx";
      };
      icecastSourcePassword = {
        sopsFile = ./secrets.yaml;
        key = "icecast/sourcePassword";
      };
      icecastRelayPassword = {
        sopsFile = ./secrets.yaml;
        key = "icecast/relayPassword";
      };
      icecastAdminPassword = {
        sopsFile = ./secrets.yaml;
        key = "icecast/adminPassword";
      };
    };

    systemd.services.icecast = {
      after = [ "network.target" ];
      description = "Icecast Network Audio Streaming Server";
      wantedBy = [ "multi-user.target" ];

      preStart = "mkdir -p /var/log/icecast && chown nobody:nogroup /var/log/icecast";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.icecast}/bin/icecast -c ${config.sops.templates."icecast.xml".path}";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        Restart = "always";
        RestartSec = 5;
      };
    };

    services.nginx.enable = true;
    services.nginx.virtualHosts."${hostFqdn}" = {
      forceSSL = true;
      enableACME = true;
      serverAliases = cfg.acmeExtraSANs;
      locations."/" = {
        extraConfig = "root ${statsXsl}/public/;";
      };
      locations."/backend/" = {
        proxyPass = "http://127.0.0.1:8082";
        extraConfig = ''
          auth_basic "stream-api login";
          auth_basic_user_file ${config.sops.secrets.htpasswd.path};
        '';
      };
      locations."/stats/" = {
        proxyPass = "http://127.0.0.1:9999";
        extraConfig = ''
          auth_basic "stream-api login";
          auth_basic_user_file ${config.sops.secrets.htpasswd.path};
        '';
      };
      locations."/stats/srt" = {
        proxyPass = "http://127.0.0.1:8084/streams";
        extraConfig = ''
          auth_basic "stream-api login";
          auth_basic_user_file ${config.sops.secrets.htpasswd.path};
        '';
      };
    };

    security.acme.certs."${hostFqdn}".extraDomainNames = cfg.acmeExtraSANs;

    services.nginx.appendConfig = ''
      include "${config.sops.templates."nginx-rtmp.conf".path}";
    '';
    services.nginx.appendHttpConfig = ''
      # vhost for stats
      server {
        server_name _;

        listen 127.0.0.1:9999;
        allow ::1;
        allow 127.0.0.1;

        # stats
        location ~* ^/stats/nginx {
          stub_status on;
        }

        location ~* ^/stats/rtmp {
          rtmp_stat all;
          rtmp_stat_stylesheet /stat.xsl;
        }

        location /control {
          rtmp_control all;
        }
      }
    '';

    networking.firewall.allowedTCPPorts = [ 80 443 1935 8000 ];

    environment.systemPackages = with pkgs; [
      stream-api
    ];
    systemd.services."stream-api" = {
      after = [ "consul.service" ];
      requires = [ "consul.service" ];
      serviceConfig = {
        ExecStart = "${pkgs.stream-api}/bin/stream-api -config ${streamApiConfigFile}";
        Restart = "always";
        RestartSec = 5;
      };
      wantedBy = [ "multi-user.target" ];
      restartIfChanged = true;
      restartTriggers = [ streamApiConfigFile ];
    };
  };
}

