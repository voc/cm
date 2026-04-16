{ config, lib, pkgs, ... }:

with lib;

# voc-mirrorbits module
#
# Mirrorbits is a geographical download redirector written in Go for
# distributing files efficiently across a set of mirrors.
#
let cfg = config.services.voc-mirrorbits;
  fqdn = config.networking.hostName + "." + config.networking.domain;
  configFile = pkgs.writeText "mirrorbits.conf" ''
    Repository: /srv/ftp
    Templates: ${pkgs.mirrorbits-voc}/share/templates/
    OutputMode: auto
    ListenAddress: "[::1]:8080"
    Gzip: false
    RedisAddress: "[::1]:6379"
    RedisPassword:
    RPCListenAddress: "[::1]:3390"
    LogDir: /var/log/mirrorbits/
    GeoipDatabasePath: /var/lib/GeoIP/
    ConcurrentSync: 5
    ScanInterval: 30
    CheckInterval: 1
    RepositoryScanInterval: 5
    Hashes:
        SHA1: On
        SHA256: On
        MD5: Off
    DisallowRedirects: false
    WeightDistributionRange: 1.5
    DisableOnMissingFile: false
    MaxLinkHeaders: 10
    Fallbacks:
        - URL: ${config.services.voc-mirrorbits.fallback}
          CountryCode: de
    GoogleMapsAPIKey:
  '';
in {
  options = {
    services.voc-mirrorbits = {
      enable = mkEnableOption "voc-mirrorbits";
      fallback = mkOption {
        type = types.str;
        description = "Server to use when file has not been indexed yet.";
        default = "https://ffmuc.media.ccc.de/";
      };
    };
  };

  config = mkIf cfg.enable {
    sops.secrets = {
      geoIPlicenseKey = {
        sopsFile = ./secrets.yaml;
        key = "geoIPlicenseKey";
      };
      mirrorbits_lednsapi = {
        sopsFile = ./secrets.yaml;
        key = "lednsapiKey";
        owner = config.users.users.acme.name;
      };
    };

    services.geoipupdate = {
      enable = true;
      settings = {
        AccountID = 711866;
        EditionIDs = [
          "GeoLite2-ASN"
          "GeoLite2-City"
          "GeoLite2-Country"
        ];
        DatabaseDirectory = "/var/lib/GeoIP";
        LicenseKey = { _secret = config.sops.secrets.geoIPlicenseKey.path; };
      };
    };

    services.redis.servers.mirrorbits = {
      enable = true;
      appendOnly = true;
      save = [];
      bind = "::1";
      port = 6379;
    };

    systemd.services.mirrorbits = {
      serviceConfig = {
        ExecStart = "${pkgs.mirrorbits-voc}/bin/mirrorbits daemon -config ${configFile} -p /run/mirrorbits/mirrorbits.pid";
        ExecReload = "/bin/kill -HUP $MAINPID";
        ExecStop = "-/bin/kill -QUIT $MAINPID";
        DynamicUser = "yes";
        Restart = "always";
        RestartSec = 5;
        LogsDirectory = "mirrorbits";
        RuntimeDirectory = "mirrorbits";
      };
      wantedBy = [ "multi-user.target" ];
      restartIfChanged = true;
      restartTriggers = [ configFile ];
    };

    systemd.services.mirrorbits-serverlist-api = {
      serviceConfig = {
        ExecStart = "${pkgs.mirrorbits-serverlist-api}/bin/mirrorbits-serverlist-api";
        ExecReload = "/bin/kill -HUP $MAINPID";
        ExecStop = "-/bin/kill -QUIT $MAINPID";
        Environment = "API_URL=[::1]:8000";
        DynamicUser = "yes";
        Restart = "always";
        RestartSec = 5;
      };
      wantedBy = [ "multi-user.target" ];
      restartIfChanged = true;
      restartTriggers = [ configFile ];
    };

    environment.systemPackages = with pkgs; [
      mirrorbits-voc
    ];

    services.nginx.enable = true;
    services.nginx.appendHttpConfig = ''
      # Add HSTS header with preloading to HTTPS requests.
      # Adding this header to HTTP requests is discouraged
      map $scheme $hsts_header {
          https   "max-age=31536000; includeSubdomains; preload";
      }
      add_header Strict-Transport-Security $hsts_header;
    '';

    services.nginx.virtualHosts."cdn.media.ccc.de" = {
      addSSL = true;
      useACMEHost = "cdn.media.ccc.de";
      root = "/srv/ftp";
      serverAliases = [ "ftp.media.ccc.de" "ftp.ccc.de" ];
      locations."/.zfs" = {
        extraConfig = "deny all;";
        priority = 10;
      };
      locations."/favicon.ico" = {
        root = "/srv/www/media.ccc.de/root";
        priority = 10;
      };
      locations."/images/" = {
        alias = "/srv/www/cdn.media.ccc.de/images/";
        priority = 10;
      };
      locations."~ \\.srt$" = {
        extraConfig = ''
          if (-f $request_filename) {
            break;
          }

          rewrite ^/(.*\.srt)$ $scheme://mirror.selfnet.de/c3subtitles/$1 last;
          break;
        '';
        priority = 50;
      };
      locations."~ \\.vtt$" = {
        extraConfig = ''
          if (-f $request_filename) {
            break;
          }

          rewrite ^/(.*\.vtt)$ $scheme://static.media.ccc.de/media/$1 last;
          break;
        '';
        priority = 50;
      };
      locations."/" = {
        extraConfig = ''
          if ($http_origin ~ ^http(s?):\/\/[^/]*events\.ccc\.de$) {
            return 307 https://${fqdn}$request_uri$is_args$args;
          }
          add_header Access-Control-Allow-Origin *;
          autoindex on;
          try_files $uri/ @cdn;
        '';
        priority = 100;
      };
      locations."@cdn" = {
        extraConfig = ''
          set $remote_addr_v4 $remote_addr;
          if ($remote_addr ~* ^::ffff:(.*)) {
            set $remote_addr_v4 $1;
          }
          proxy_set_header X-Forwarded-For $remote_addr_v4;
          proxy_set_header X-Forwarded-Proto http;
          proxy_pass http://[::1]:8080;
        '';
        priority = 101;
      };
    };

    services.nginx.virtualHosts."cdn-api.media.ccc.de" = {
      addSSL = true;
      useACMEHost = "cdn.media.ccc.de";

      locations."/" = {
        extraConfig = ''
          add_header 'Access-Control-Allow-Origin' '*';
          proxy_pass      http://[::1]:8000;
        '';
      };

      # TODO: admin api
      #locations."/" = {
      #  extraConfig = ''
      #    add_header 'Access-Control-Allow-Origin' '*';
      #    proxy_pass      http://[::1]:5000;
      #  '';
      #};
    };

    security.acme.certs."cdn.media.ccc.de" = {
      # server = "https://acme-staging-v02.api.letsencrypt.org/directory";
      dnsProvider = "exec";
      email = "contact@c3voc.de";
      reloadServices = [ "nginx.service" ];
      group = "nginx";
      extraDomainNames = [
        "cdn-api.media.ccc.de"
        "ftp.media.ccc.de"
      ];
      environmentFile =
        let
          script = pkgs.writeShellScript "ledns-challenge.sh" (
            import ./ledns-challenge.nix {
              curl = pkgs.curl;
              secretpath = config.sops.secrets.mirrorbits_lednsapi.path;
            }
          );
        in
        pkgs.writeText "env" ''
          EXEC_PATH=${script}
        '';
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };
}

