{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let cfg = config.services.voc-knot;
  isPrimary = ((config.services.voc-knot.primary or "${config.networking.hostName}.${config.networking.domain}") == "${config.networking.hostName}.${config.networking.domain}");
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


