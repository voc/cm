{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.voc-ingest;
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
      };
    };

    services.nginx.enable = true;
    services.nginx.virtualHosts."${config.networking.hostName}.${config.networking.domain}" = {
      forceSSL = true;
      enableACME = true;
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

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    environment.systemPackages = with pkgs; [
      stream-api
    ];
    systemd.services."stream-api" = {
      serviceConfig = {
        ExecStart = "${pkgs.stream-api}/bin/stream-api -config ${streamApiConfigFile}";
      };
      wantedBy = [ "multi-user.target" ];
      restartIfChanged = true;
      restartTriggers = [ streamApiConfigFile ];
    };
  };
}

