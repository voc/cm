{ config, lib, pkgs, ... }:

with lib;

let
  perlModules = with pkgs.perlPackages; [
    Moo
    TextCSV_XS
    YAMLLibYAML
    #ModPerlUtil
    MailIMAPClient
    JSONXS
    EncodeHanExtra
    CryptEksblowfish
    DataUUID
    DateTimeTimeZone
    DateTime
    DBDPg
    DBI
    HashMerge
    NetLDAP
    NetDNS
    TemplateToolkit
    XMLLibXML
    XMLLibXSLT
    XMLParser
    SpreadsheetXLSX
    PackageStash
    JavaScriptMinifierXS
    CSSMinifierXS
    iCalParser
    namespaceautoclean
    AuthenSASL
    CryptJWT
    CryptOpenSSLX509
    DBDmysql
    IOSocketSSL
    NTLM
    FileSlurper
  ];
  pkg = pkgs.stdenv.mkDerivation rec {
    pname = "znuny";
    version = "7.1.3";

    src = pkgs.fetchFromGitHub {
      owner = "znuny";
      repo = "Znuny";
      rev = "rel-${builtins.replaceStrings ["."] ["_"] version}";
      hash = "sha256-BWJ6I30yLvBSrwm4ADFVXbSdhSUArrVae8ThJLycoow=";
    };

    nativeBuildInputs = with pkgs; [
      makeWrapper
    ];

    buildInputs = with pkgs; [
      perlPackages.perl
    ] ++ perlModules;

    installPhase = ''
      mkdir $out
      cp --recursive ./* $out/
      mv $out/Kernel/Config $out/Kernel/Config.dist
      mv $out/var/cron $out/var/cron.dist
      ln -fs /var/lib/znuny/config/Config $out/Kernel/Config
      ln -fs /var/lib/znuny/config/Config.pm $out/Kernel/Config.pm
      ln -fs /var/lib/znuny/var/tmp $out/var/tmp
      ln -fs /var/lib/znuny/var/run $out/var/run
      ln -fs /var/lib/znuny/var/cron $out/var/cron
      ln -fs /var/lib/znuny/var/httpd/htdocs/js/js-cache $out/var/httpd/htdocs/js/js-cache
      ln -fs /var/lib/znuny/var/httpd/htdocs/skins/Agent/default/css-cache $out/var/httpd/htdocs/skins/Agent/default/css-cache
      rm -rf $out/var/log
      ln -fs /var/log/znuny/ $out/var/log
    '';

    postFixup = ''
      for i in $(find $out/bin/ -type f); do
        wrapProgram $i \
          --prefix PERL5LIB : "${pkgs.perlPackages.makeFullPerlPath perlModules}"
      done
      wrapProgram $out/scripts/MigrateToZnuny7_1.pl \
        --prefix PERL5LIB : "${pkgs.perlPackages.makeFullPerlPath perlModules}"
    '';
  };

  znunyConfig = pkgs.writeText "znuny-config.pm" ''
    package Kernel::Config;

    use strict;
    use warnings;
    use utf8;

    sub Load {
        my $Self = shift;
        $Self->{DatabaseDSN} = "DBI:Pg:dbname=znuny;";

        $Self->{Home} = '${pkg}';

        $Self->{SecureMode} = 1;

        ${cfg.extraConfig}

        return 1;
    }

    use Kernel::Config::Defaults; # import Translatable()
    use parent qw(Kernel::Config::Defaults);

    1;
  '';

  znunyConsole = pkgs.writeScriptBin "znuny" ''
    sudo -u ${cfg.user} ${pkg}/bin/znuny.Console.pl $@
  '';

  cfg = config.services.znuny;
in
{
  options.services.znuny = {
    enable = mkEnableOption "Enable Znuny web-based ticketing system";
    pkg = mkOption {
      type = types.path;
      default = pkg;
    };
    unixSocket = mkOption {
      type = types.str;
      default = "/run/znuny.sock";
    };
    user = mkOption {
      type = types.str;
      default = "znuny";
      readOnly = true;
    };
    group = mkOption {
      type = types.str;
      default = "znuny";
      readOnly = true;
    };
    prefork = mkOption {
      type = types.ints.positive;
      default = 1;
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
    };

    nginxVirtualHostConfig = mkOption {
      type = types.attrs;
      readOnly = true;
      default = {
        root = "${pkg}/var/httpd/htdocs";
        locations."/favicon.ico".extraConfig = ''
          access_log    off;
          log_not_found off;
        '';
        locations."/znuny-web/".alias = "${pkg}/var/httpd/htdocs/";
        locations."~ ^/znuny/(.*\\.pl)(/.*)?$".extraConfig = ''
          gzip off;
          fastcgi_pass unix:${cfg.unixSocket};
          fastcgi_index index.pl;
          fastcgi_param SCRIPT_FILENAME ${pkg}/bin/cgi-bin/$1;

          fastcgi_param QUERY_STRING $query_string;
          fastcgi_param REQUEST_METHOD $request_method;
          fastcgi_param CONTENT_TYPE $content_type;
          fastcgi_param CONTENT_LENGTH $content_length;

          fastcgi_param SCRIPT_FILENAME $request_filename;
          fastcgi_param SCRIPT_NAME $fastcgi_script_name;
          fastcgi_param REQUEST_URI $request_uri;
          fastcgi_param DOCUMENT_URI $document_uri;
          fastcgi_param DOCUMENT_ROOT $document_root;
          fastcgi_param SERVER_PROTOCOL $server_protocol;

          fastcgi_param GATEWAY_INTERFACE CGI/1.1;
          fastcgi_param SERVER_SOFTWARE nginx/$nginx_version;

          fastcgi_param REMOTE_ADDR $remote_addr;
          fastcgi_param REMOTE_PORT $remote_port;
          fastcgi_param SERVER_ADDR $server_addr;
          fastcgi_param SERVER_PORT $server_port;
          fastcgi_param SERVER_NAME $server_name;

          fastcgi_param HTTPS $https if_not_empty;
        '';
      };
    };
  };

  config = mkIf cfg.enable {

    services.postgresql.enable = true;
    services.postgresql.ensureUsers = [{
      name = "znuny";
      ensureDBOwnership = true;
    }];
    services.postgresql.ensureDatabases = [
      "znuny"
    ];

    environment.systemPackages = [
      znunyConsole
    ];

    users.users."${cfg.user}" = {
      isSystemUser = true;
      group = cfg.group;
    };
    users.users."nginx".extraGroups = [ cfg.group ];
    users.groups."${cfg.group}" = {};

    systemd.tmpfiles.rules = [
      "d /var/lib/znuny/config 0755 ${cfg.user} ${cfg.group}"
      "d /var/lib/znuny/var/tmp 0755 ${cfg.user} ${cfg.group}"
      "d /var/lib/znuny/var/run 0755 ${cfg.user} ${cfg.group}"
      "d /var/lib/znuny/var/cron 0755 ${cfg.user} ${cfg.group}"
      "d /var/lib/znuny/var/httpd/htdocs/js/js-cache 0755 ${cfg.user} ${cfg.group}"
      "d /var/lib/znuny/var/httpd/htdocs/skins/Agent/default/css-cache 0755 ${cfg.user} ${cfg.group}"
      "d /var/log/znuny 0755 ${cfg.user} ${cfg.group}"
    ];

    services.fcgiwrap.instances."znuny".socket.user = "nginx";
    services.fcgiwrap.instances."znuny".socket.group = cfg.group;
    services.fcgiwrap.instances."znuny".socket.type = "unix";
    services.fcgiwrap.instances."znuny".socket.address = cfg.unixSocket;
    services.fcgiwrap.instances."znuny".process.user = cfg.user;
    services.fcgiwrap.instances."znuny".process.group = cfg.group;
    services.fcgiwrap.instances."znuny".process.prefork = cfg.prefork;
    systemd.sockets."fcgiwrap-znuny" = {
      requires = [ "nginx.service" ];
      after = [ "nginx.service" ];
    };

    systemd.services."znuny-daemon" = {
      path = [ pkgs.postgresql ];
      wantedBy = [ "multi-user.target" ];
      after = [ "postgresql.service" "systemd-tmpfiles-resetup.service" ];
      requires = [ "postgresql.service" ];
      preStart = ''
        rm -rf /var/lib/znuny/Config
        cp --recursive --force --no-preserve=mode ${pkg}/Kernel/Config.dist /var/lib/znuny/config/Config
        cp --force ${znunyConfig} --no-preserve=mode /var/lib/znuny/config/Config.pm
        cp --force --no-preserve=mode ${pkg}/var/cron.dist/* /var/lib/znuny/var/cron/

        TABLES=$(psql znuny --csv -t -c "select count(*) from information_schema.tables where table_schema = 'public';" | tr -d '[:blank:]')
        echo $TABLES
        if [ "$TABLES" -eq "0" ]; then
          echo "Empty database, start init"
          psql znuny < ${pkg}/scripts/database/schema.postgresql.sql
          psql znuny < ${pkg}/scripts/database/initial_insert.postgresql.sql
          psql znuny < ${pkg}/scripts/database/schema-post.postgresql.sql
        else
          echo "Database allready initialized, start migration"
          ${pkg}/scripts/MigrateToZnuny7_1.pl
        fi

        ${pkg}/bin/znuny.Console.pl Maint::Config::Rebuild
      '';
      serviceConfig = {
        ExecStart = "${pkg}/bin/znuny.Daemon.pl start --foreground";
        User = cfg.user;
        TimeoutStartSec = "300";
      };
    };
  };
}
