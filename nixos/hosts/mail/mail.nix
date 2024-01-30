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
      "cm@c3voc.de" = "cm@lists.c3voc.de";
      "congress@c3voc.de" = "congress@lists.c3voc.de";
      "media@c3voc.de" = "media@lists.c3voc.de";
      "muenchen@c3voc.de" = "muenchen@lists.c3voc.de";
      "studios@c3voc.de" = "studios@lists.c3voc.de";
      "voc@c3voc.de" = "voc@lists.c3voc.de";
    };

    # whitelist SPF checks from mng (for now)
    policydSPFExtraConfig = ''
      HELO_Whitelist = mng.c3voc.de
      skip_addresses = 127.0.0.0/8,::ffff:127.0.0.0/104,::1,185.106.84.49,2001:67c:20a0:e::179
    '';
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
      reject = null; # Disable rejects, default is 15
      add_header = 4; # Add header when reaching this score
      greylist = 10; # Apply greylisting when reaching this score
    }
  '';

  users.users.uwsgi.uid = config.ids.uids.uwsgi;
  users.users.uwsgi.group = "uwsgi";
  users.groups.uwsgi.gid = config.ids.gids.uwsgi;
}
