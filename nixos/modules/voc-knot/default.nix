{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let cfg = config.services.voc-knot;
  isPrimary = ((config.services.voc-knot.primary or "${config.networking.hostName}.${config.networking.domain}") == "${config.networking.hostName}.${config.networking.domain}");
  pythonPackages = self: with self; [
    pyyaml
    flask
    cryptography
  ];
in
{
  options = {
    services.voc-knot = {
      enable = mkEnableOption "voc-ingest";
      primary = mkOption {
        type = types.str;
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # disable resolved listener
      services.resolved.extraConfig = ''
        DNSStubListener=no
      '';

      # enable knot
      services.knot.enable = true;
      services.knot.settingsFile = "/etc/knot/voc-knot.conf";
      systemd.services.knot.unitConfig.ConditionPathExists = "/etc/knot/voc-knot.conf";

      services.telegraf.extraConfig = {
        global_tags.role = "knot";
      };

      networking.firewall.allowedUDPPorts = [ 53 ];
      networking.firewall.allowedTCPPorts = [ 53 ];
    }

    (mkIf isPrimary {
      users.users.voc.extraGroups = ["knot"];

      environment.systemPackages = with pkgs; [
        git
        (pkgs.python3.withPackages pythonPackages)
        knot-dns
      ];

      services.uwsgi.enable = true;
      services.uwsgi.plugins = ["python3"];
      services.uwsgi.user = "root";
      services.uwsgi.group = "root";
      services.uwsgi.instance = {
        type = "emperor";
        vassals = {
          lednsapi = {
            type = "normal";
            pythonPackages = pythonPackages;
            cap = "setgid,setuid";
            socket = "/run/knot/lednsapi.sock";
            immediate-uid = "knot";
            immediate-gid = "nginx";
            chmod-socket = "660";
            module = "app:app";
            chdir = "/opt/lednsapi";
          };
        };
      };

      services.nginx.enable = true;
      services.nginx.virtualHosts."lednsapi.c3voc.de" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          extraConfig = "uwsgi_pass unix:///run/knot/lednsapi.sock;";
        };
      };
      services.nginx.virtualHosts."${config.networking.hostName}.${config.networking.domain}" = {
        forceSSL = false;
        enableACME = true;
        serverAliases = ["ns0.c3voc.de" "ns100.c3voc.de"];
        locations."/" = {
          extraConfig = "root /var/www/html/;";
        };
      };

      networking.firewall.allowedTCPPorts = [ 80 443 ];

      environment.etc."telegraf/dns-stats.py".mode = "0755";
      environment.etc."telegraf/dns-stats.py".text = ''
        #!/usr/bin/env python3

        import subprocess
        import json

        statout = subprocess.check_output(["knotc", "stats"]).decode()

        stats = {}
        for line in statout.splitlines():
            line = line.strip()
            if not line:
                continue
            key, value = line.replace(".", "_").replace("-", "_").replace("[", "_").replace("]", "").split(" = ", 1)
            stats[key] = int(value)

        print(json.dumps(stats))
      '';

      environment.etc."knot/update.sh".mode = "0755";
      environment.etc."knot/update.sh".text = ''
        #!/usr/bin/env bash

        set -e
        set -o pipefail

        if [ ! -d /var/www/html/config ]; then
          sudo mkdir -p /var/www/html/config
          sudo chown knot: /var/www/html/config
        fi
        sudo -u knot mkdir -p /var/lib/knot/zones /var/lib/knot/home

        sudo rm -f /tmp/secondary_*
        sudo chown -R knot:knot /etc/knot
        sudo chmod 770 /etc/knot

        cd /etc/knot/repo && sudo -u knot env HOME=/var/lib/knot/home ./update.py
        cd /etc/knot/repo && sudo -u knot env HOME=/var/lib/knot/home ./update.py
      '';

      security.sudo.extraConfig = ''
        knot ALL=NOPASSWD: /run/current-system/sw/bin/systemctl is-active knot
        knot ALL=NOPASSWD: /run/current-system/sw/bin/systemctl reload knot
        knot ALL=NOPASSWD: /run/current-system/sw/bin/systemctl reset-failed knot
        knot ALL=NOPASSWD: /run/current-system/sw/bin/systemctl start knot
      '';
    })

    (mkIf (! isPrimary) {
      sops.templates."update.sh".content = ''
        #!/usr/bin/env bash

        PRIMARY="${config.services.voc-knot.primary}"
        HOSTNAME="${config.networking.hostName}.${config.networking.domain}"
        PASSWORD="${config.sops.placeholder.dnsKeyType}:${config.sops.placeholder.dnsKey}"

        set -e
        set -o pipefail

        if [ ! -e /etc/knot/voc-knot.conf ]; then
          sha1sum=""
        else
          sha1sum="$(${pkgs.coreutils}/bin/sha1sum /etc/knot/voc-knot.conf | ${pkgs.gawk}/bin/awk '{print $1}')"
        fi

        ${pkgs.curl}/bin/curl -s "http://''\${PRIMARY}/config/''\${HOSTNAME}.conf.asc" | ${pkgs.gnupg}/bin/gpg --armor --batch --passphrase "''\${PASSWORD}" -d > /tmp/new.conf 2> /dev/null

        if [ "$(${pkgs.coreutils}/bin/sha1sum /tmp/new.conf | ${pkgs.gawk}/bin/awk '{print $1}')" = "''\${sha1sum}" ]; then
          exit 0
        fi

        if [ ! -e /etc/knot/voc-knot.conf ]; then
          echo "Zone config created"
          mv /tmp/new.conf /etc/knot/voc-knot.conf
          systemctl restart knot
        else
          echo "Zone config updated"
          mv /tmp/new.conf /etc/knot/voc-knot.conf
          systemctl reload knot
        fi
      '';

      sops.secrets = {
        dnsKey = {
          sopsFile = ./secrets.yaml;
          key = "${config.networking.hostName}.${config.networking.domain}/key";
        };
        dnsKeyType = {
          sopsFile = ./secrets.yaml;
          key = "${config.networking.hostName}.${config.networking.domain}/keytype";
        };
      };

      systemd.services."knot-update" = {
        serviceConfig = {
          ExecStart = "${pkgs.bash}/bin/bash ${config.sops.templates."update.sh".path}";
          Type = "oneshot";
          RemainAfterExit = true;
        };
        restartIfChanged = true;
      };

      systemd.timers."knot-update" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "5m";
          OnUnitActiveSec = "5m";
          Unit = "knot-update.service";
        };
      };
    })
  ]);
}


