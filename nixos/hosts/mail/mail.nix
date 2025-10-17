{ config, lib, pkgs, inputs, ... }:

let
  OWNER_EMAIL = "postmaster@c3voc.de";  # Change this!
  MAILMAN_HOST = "lists.c3voc.de";    # Change this!
in {
  imports = [ inputs.nixos-mailserver.nixosModule ];

  # reduce log spam
  systemd.services.rspamd.serviceConfig.LogLevelMax =
    3; # this is set to error because rspamd regularly complains about not enough learns
  systemd.services.dovecot2.serviceConfig.LogLevelMax = 5; # = notice

  # stop postfix from dying if rspamd hiccups
  systemd.services.postfix.unitConfig = {
    Requires = lib.mkForce "dovecot2.service opendkim.service";
  };

  mailserver = {
    mailDirectory = "/persist/mail";
    enable = true;
    fqdn = "mail.c3voc.de";
    domains = [
      "c3voc.de"
    ];

    # Use Let's Encrypt certificates. Note that this needs to set up a stripped
    # down nginx and opens port 80.
    certificateScheme = "acme-nginx";

    # Only allow implict TLS
    enableImap = false;
    enablePop3 = false;

    forwards = {
      "cm" = "cm@lists.c3voc.de";
      "congress" = "congress@lists.c3voc.de";
      "media" = "media@lists.c3voc.de";
      "muenchen" = "muenchen@lists.c3voc.de";
      "studios" = "studios@lists.c3voc.de";
      "voc" = "voc@lists.c3voc.de";
    } // lib.genAttrs [ # rt related addresses
      "rt"
      "rt-comment"
      "rt-test"
    ] (addr: "${addr}@rt.c3voc.de");
  };

  sops.secrets.aliases = {};

  services.postfix = {
    mapFiles.virtual_cm = config.sops.secrets.aliases.path;
    relayDomains = ["hash:/var/lib/mailman/data/postfix_domains"];
    config = {
      mydestination = lib.mkForce ["c3voc.de"];
      transport_maps = ["hash:/var/lib/mailman/data/postfix_lmtp"];
      local_recipient_maps = ["hash:/var/lib/mailman/data/postfix_lmtp"];
      virtual_alias_maps = ["hash:/etc/postfix/virtual_cm"];
    };
    networks = [
      "127.0.0.1/32"
      "[::1]/128"

      # rt.c3voc.de
      "185.106.84.19/32"
      "[2001:67c:20a0:e::19]/128"

      # pretalx.c3voc.de
      "31.172.33.105/32"
      "[2a01:a700:48d1::105]/128"

      # hub.test.c3voc.de
      "195.54.164.162/32"
      "2001:67c:20a0:e::162/128"
    ];
  };

  services.mailman = {
    enable = true;
    serve.enable = true;
    siteOwner = OWNER_EMAIL;
    webUser = config.services.uwsgi.user;
    hyperkitty.enable = true;
    webHosts = [ MAILMAN_HOST ];
    webSettings.POSTORIUS_TEMPLATE_BASE_URL = "https://${MAILMAN_HOST}/";
  };

  services.nginx = {
    virtualHosts.${MAILMAN_HOST} = {
      enableACME = true;
      forceSSL = true;
      locations."~ ^/(?:pipermail|private)/([a-z-]+)/".return = "303 https://${MAILMAN_HOST}/hyperkitty/list/$1.${MAILMAN_HOST}/";
      locations."~ ^/(?:listadmin)/([a-z-]+)".return = "303 https://${MAILMAN_HOST}/postorius/lists/$1.${MAILMAN_HOST}/settings/";
      locations."~ ^/(?:listinfo|options)/([a-z-]+)".return = "303 https://${MAILMAN_HOST}/postorius/lists/$1.${MAILMAN_HOST}/";
      locations."/create".return = "301 https://${MAILMAN_HOST}/postorius/lists/new";
    };
  };

  services.rspamd.extraConfig = ''
    actions {
      greylist = 2; # Apply greylisting when reaching this score
      add_header = 4; # Add header when reaching this score
      reject = 6; # yeeeeeeeet from 6 on
    }
  '';

  users.users.uwsgi.uid = config.ids.uids.uwsgi;
  users.users.uwsgi.group = "uwsgi";
  users.groups.uwsgi.gid = config.ids.gids.uwsgi;
}
