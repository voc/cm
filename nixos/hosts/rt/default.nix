{ lib, modulesPath, pkgs, ... }:

with lib;

let
  multiwatch = pkgs.stdenv.mkDerivation rec {
    pname = "multiwatch";
    version = "master";

    src = pkgs.fetchFromGitHub {
      owner = "lighttpd";
      repo = "multiwatch";
      rev = "master";
      hash = "sha256-yYE5Q2lKLVrd7u8B/0ZVvEpWi3zGMMZuEODAP0lL/Yg=";
    };

    nativeBuildInputs = with pkgs; [
      cmake
      pkg-config
    ];

    buildInputs = with pkgs; [
      glib
      libev
    ];

    configurePhase = ''
      cmake .
    '';

    buildPhase = ''
      make
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp multiwatch $out/bin/
    '';
  };

  pathsOverride = pkgs.writeText "rt-paths-override.pm" ''
    $MasonDataDir = '/var/lib/rt/data/';
    $MasonSessionDir = '/var/lib/rt/session/';
  '';

  config = pkgs.writeText "rt-config.pm" ''
    # Single-quote all values EXCEPT the special value `undef`
    # that turns off a setting.

    # rtname appears in ticket email subjects. It needs to be globally unique,
    # so use your organization's domain name.
    Set($rtname, 'c3voc');
    # Organization is used in the database for ticket links, etc. It also needs to
    # be globally unique, so use your organization's domain name.
    Set($Organization, 'c3voc.de');
    # WebDomain is domain name of the RT web server. RT uses it to construct links
    # and defend against CSRFs.
    Set($WebDomain, 'rt.c3voc.de');
    # WebPort is the port where the RT web server runs. Edit the number below if
    # you're not using the standard HTTPS port.
    Set($WebPort, '443');
    # WebPath is the path where the RT web server runs on your WebDomain.
    # Edit the path below only if you're using a specific path like example.com/rt
    Set($WebPath, "");

    # DatabaseUser is the name of the database account RT uses to read and store
    # data. 'rt_user' is the default but you can change it if you like.
    # DO NOT use the 'rt_admin' superuser created in the instructions above.
    Set($DatabaseUser, 'rt');
    # DatabasePassword is the password for DatabaseUser.
    Set($DatabasePassword, ' ');
    # DatabaseHost is the hostname of the database server RT should use.
    # Change 'localhost' if it lives on a different server.
    Set($DatabaseHost, '/run/postgresql');
    # DatabasePort is the port number of the database server RT should use.
    # `undef` means the default for that database. Change it if you're not
    # using the standard port.
    Set($DatabasePort, undef);
    # DatabaseName is the name of RT's database hosted on DatabaseHost.
    # 'rt5' is the default but you can change it if you like.
    Set($DatabaseName, 'rt');
    # DatabaseAdmin is the name of the user in the database used to perform
    # major administrative tasks. Change 'rt_admin' if you're using a user
    # besides the one created in this guide.
    Set($DatabaseAdmin, 'rt');

    # RT can log to syslog, stderr, and/or a dedicated file.
    # Log settings are used both by the primary server and by command line
    # tools like rt-crontool, rt-ldapimport, etc.
    # You set all of RT's $LogTo* paramaters to a standard log level: 'debug',
    # 'info', 'notice', 'warning', 'error', 'critical', 'alert', or 'emergency'.
    # For a modern install, if you log to syslog, it goes
    # to journald where it's easy to query and automatically gets rotated.
    # Some syslogs log only warn and error, so lower levels like debug won't appear here.
    Set($LogToSyslog, 'warning');

    # When the RT server logs to stderr, that will go to the rt-server journal.
    # Command line tools log to their own stderr. Setting this to
    # 'warning' or 'error' helps ensure you get notified if RT's cron jobs
    # encounter problems.
    # When running with Apache, these logs will go to the Apache error log,
    # which should be set up with logrotate automatically.
    Set($LogToSyslog, 'warning');
    Set($LogToSTDERR, 'warning');

    # Turn off optional features that require additional configuration.
    # If you want to use these, refer to the RT_Config documentation for
    # instructions on how to set them up.
    Set(%GnuPG, 'Enable' => '0');
    Set(%SMIME, 'Enable' => '0');

    Set($CorrespondAddress, "rt@c3voc.de");
    Set($CommentAddress, "rt-comment@c3voc.de");
    Set($SendmailPath, '${pkgs.msmtp}/bin/sendmail');
    Set($OwnerEmail, "voc-rt-admin@julianjacobi.net");

    Set( %FullTextSearch,
        Enable     => 1,
        Indexed    => 1,
        Column     => 'ContentIndex',
        Table      => 'AttachmentsIndex',
    );

    # Perl expects to find this 1 at the end of the file.
    1;
  '';

  baseUnit = {
    path = [
      pkgs.w3m
    ];
    preStart = ''
      ${pkgs.coreutils}/bin/cp ${config} /var/lib/rt/RT_SiteConfig.pm
      ${pkgs.coreutils}/bin/chmod 0644 /var/lib/rt/RT_SiteConfig.pm
    '';
    environment = {
      RT_SITE_CONFIG = "/var/lib/rt/RT_SiteConfig.pm";
      RT_PATHS_OVERRIDE = pathsOverride;
    };
  };

  workerCount = 5;
in
{
  imports = [
    "${modulesPath}/virtualisation/proxmox-image.nix"
  ];
  config = {
    system.stateVersion = "23.11"; # do not touch


    networking.useDHCP = false;
    networking.interfaces.eth0.ipv4.addresses = [{
      address = "185.106.84.19";
      prefixLength = 26;
    }];
    networking.interfaces.eth0.ipv6.addresses = [{
      address = "2001:67c:20a0:e::19";
      prefixLength = 64;
    }];
    networking.defaultGateway = "185.106.84.1";
    networking.defaultGateway6 = "2001:67c:20a0:e::1";
    networking.nameservers = [
      "9.9.9.9"
      "1.1.1.1"
    ];

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    security.acme.acceptTerms = true;
    security.acme.defaults.email = "voc@c3voc.de";

    services.postgresql.enable = true;
    services.postgresql.ensureUsers = [{
      name = "rt";
      ensureDBOwnership = true;
    }];
    services.postgresql.ensureDatabases = [
      "rt"
    ];

    environment.systemPackages = [
      pkgs.rt
    ];

    users.users."rt".isSystemUser = true;
    users.users."rt".group = "rt";
    users.groups."rt" = {};

    systemd.tmpfiles.rules = [
      "d /var/lib/rt/ 0755 rt rt"
      "d /var/lib/rt/data/ 0755 rt rt"
      "d /var/lib/rt/session/ 0755 rt rt"
      "d /var/log/rt 0755 rt rt"
    ];

    systemd.services = (foldl (last: num: last // { 
      "rt-fcgi-${toString num}" = baseUnit // {
        after = [ "postgresql.service" ];
        wants = [ "postgresql.service" ];
        serviceConfig = {
          ExecStart = ''
            ${pkgs.rt}/sbin/rt-server.fcgi
          '';
          User = "rt";
          Group = "rt";
          StandardOutput = "journal";
          StandardInput = "socket";
          StandardError = "journal";
          Restart = "always";
        };
      };
    }) {} (builtins.genList (x: x) workerCount)) // {
      "rt-fulltext-indexer" = baseUnit // {
        serviceConfig.ExecStart = "${pkgs.rt}/sbin/rt-fulltext-indexer";
      };
      "rt-email-dashboard" = baseUnit // {
        serviceConfig.ExecStart = "${pkgs.rt}/sbin/rt-email-dashboard";
      };
      "rt-clean-sessions" = baseUnit // {
        serviceConfig.ExecStart = "${pkgs.rt}/sbin/rt-clean-sessions --older 8d";
      };
      "rt-digest-weekly" = {
        serviceConfig.ExecStart = "${pkgs.rt}/sbin/rt-email-digest -m weekly";
      };
      "rt-digest-daily" = {
        serviceConfig.ExecStart = "${pkgs.rt}/sbin/rt-email-digest -m daily";
      };
    };

    systemd.timers."rt-fulltext-indexer" = {
      timerConfig.OnCalendar = "*-*-* *:00/3:00";
    };
    systemd.timers."rt-email-dashboard" = {
      timerConfig.OnCalendar = "*-*-* *:00:00";
    };
    systemd.timers."rt-clean-sessions" = {
      timerConfig.OnCallendar = "*-*-* 05:30:00";
    };
    systemd.timers."rt-digest-weekly" = {
      timerConfig.OnCalendar = "Mon, *-*-* 04:30:00";
    };
    systemd.timers."rt-digest-daily" = {
      timerConfig.OnCalendar = "*-*-* 04:30:00";
    };

    systemd.sockets = foldl (last: num: last // {
      "rt-fcgi-${toString num}" = {
        wants = [ "network.target" ];
        after = [ "network.target" ];
        before = [ "nginx.service" ];
        wantedBy = [ "sockets.target" ];
        listenStreams = [
          "/run/rt-${toString num}.sock"
        ];
        socketConfig = {
          SocketUser = "nginx";
          SocketGroup = "nginx";
          SocketMode = "0660";
          Accept = "no";
          FreeBind = "yes";
        };
      };
    }) {} (builtins.genList (x: x) workerCount);

    services.nginx.enable = true;
    services.nginx.upstreams."rt-worker".servers = foldl (last: num: last // { "unix:/run/rt-${toString num}.sock" = {}; }) {} (builtins.genList (x: x) workerCount);
    services.nginx.virtualHosts."rt.c3voc.de" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        extraConfig = ''
          client_max_body_size 100M;

          fastcgi_param  QUERY_STRING       $query_string;
          fastcgi_param  REQUEST_METHOD     $request_method;
          fastcgi_param  CONTENT_TYPE       $content_type;
          fastcgi_param  CONTENT_LENGTH     $content_length;

          fastcgi_param  SCRIPT_NAME        "";
          fastcgi_param  PATH_INFO          $uri;
          fastcgi_param  REQUEST_URI        $request_uri;
          fastcgi_param  DOCUMENT_URI       $document_uri;
          fastcgi_param  DOCUMENT_ROOT      $document_root;
          fastcgi_param  SERVER_PROTOCOL    $server_protocol;

          fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
          fastcgi_param  SERVER_SOFTWARE    nginx/$nginx_version;

          fastcgi_param  REMOTE_ADDR        $remote_addr;
          fastcgi_param  REMOTE_PORT        $remote_port;
          fastcgi_param  SERVER_ADDR        $server_addr;
          fastcgi_param  SERVER_PORT        $server_port;
          fastcgi_param  SERVER_NAME        $server_name;
          fastcgi_param  HTTPS              $https;

          fastcgi_pass rt-worker;
        '';
      };
      locations."/static/" = {
        alias = "${pkgs.rt}/share/static/";
      };
    };

    programs.msmtp.enable = true;
    programs.msmtp.accounts.default = {
      auth = false;
      host = "mail.c3voc.de";
      from = "rt@c3voc.de";
      domain = "rt.c3voc.de";
    };

    networking.nftables.extraInput = mkAfter ''
      ip saddr 185.106.84.29/32 tcp dport 25 accept
      ip6 saddr 2001:67c:20a0:e::29/128 tcp dport 25 accept
    '';

    services.postfix.enable = true;
    services.postfix.setSendmail = false;
    services.postfix.domain = "rt.c3voc.de";
    services.postfix.destination = [ "rt.c3voc.de" ];
    services.postfix.extraAliases = ''
      rt:         "|${pkgs.rt}/bin/rt-mailgate                 --action correspond --url https://rt.c3voc.de/"
      rt-comment: "|${pkgs.rt}/bin/rt-mailgate                 --action comment    --url https://rt.c3voc.de/"
      rt-test:    "|${pkgs.rt}/bin/rt-mailgate --queue rt-test --action correspond --url https://rt.c3voc.de/"
    '';
  };
}
