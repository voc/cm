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
      "voc@c3voc.de" = [ "voc@lists.c3voc.de" "znuny@c3voc.de" ];
    };

    loginAccounts."znuny@c3voc.de" = {
      aliases = [ "znuny@c3voc.de" ];
      hashedPassword = "$2b$05$pdO2nm2sAKPIc4pT/hNBeu07xctX9BIE7ycVjpgmB8a6Bqu89e0Sq";
    };
  };

  sops.secrets.aliases = {};

  services.postfix = {
    mapFiles.virtual_cm = config.sops.secrets.aliases.path;
    relayDomains = ["hash:/var/lib/mailman/data/postfix_domains"];
    config = {
      transport_maps = ["hash:/var/lib/mailman/data/postfix_lmtp"];
      local_recipient_maps = ["hash:/var/lib/mailman/data/postfix_lmtp"];
      virtual_alias_maps = ["hash:/etc/postfix/virtual_cm"];
      virtual_alias_domains = "";
    };
    networks = [
      "127.0.0.1/32"
      "[::1]/128"

      # tickets.c3voc.de
      "185.106.84.19/32"
      "[2001:67c:20a0:e::19]/128"

      # pretalx.c3voc.de
      "31.172.33.105/32"
      "[2a01:a700:48d1::105]/128"

      # hub.test.c3voc.de
      "195.54.164.162/32"
      "[2001:67c:20a0:e::162]/128"

      # tickets.c3voc.de
      "185.106.84.19/32"
      "[2001:67c:20a0:e::19]/128"
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

  services.rspamd.locals."multimap.conf".text = let
    blocked_subjects = ''
      /\bpsoriasis\b/i
      /\bprostatitis\b/i
      /\bderila\b/i
      /\betf\b/i
      /\bbitcoin\b/i
      /\breich\b/i
      /\bgeld\b/i
      /\bki\b/i
      /\baktien\b/i
      /\bmakita\b/i
      /\blotto|lottery\b/i
      /\bmubi\b/i
      /\bauto\b/i
      /\bantihaftbeschichtung\b/i
      /.*r[:.-]*?e[:.-]*?z[:.-]*?e[:.-]*?p[:.-]*?t[:.-]*?f[:.-]*?r[:.-]*?e[:.-]*?i/i
      /\br[-_]?e[-_]?zept[-_]?frei\b/i
      /zeptfrei/i
      /\beinkommen\b/i
      /\bnubuu\b/i
      /\bnuubu\b/i
      /\bentgiftungsprogramm\b/i
      /\bgelenkschmerzen\b/i
      /\bmädchen\b/i
      /\bsprachübersetzer\b/i
      /\bstabilisierung.+blutdrucks\b/i
      /\bmüheloses.+reinigen\b/i
      /\bpapillome\b/i
      /\bküchenmesser\b/i
      /\brendite\b/i
      /\bgewichtsverlust\b/i
      /\bpreissturz\b/i
      /\bchance.+kostenlos\b/i
      /\bhamorrhoiden\b/i
      /\bhörvermögens\b/i
      /\bmuama\b/i
      /\bryoko\b/i
      /\bbambusseide\b/i
      /\bluxusseide\b/i
      /\bHondrostrong\b/i
      /\btabletten.+apotheke\b/i
      /\bEinlegesohlen\b/i
      /\bEinlegesohlen\b/i
      /\btest\syour\siq\snow\b/i
      /\bzukunft.+sauberkeit\b/i
      /\bcbd\b/i
      /\bharninkontinenz\b/i
      /\bpillen\b/i
      /\btabletten\b/i
    '';
    greylist_tlds = ''
      [.]tr$
      [.]su$
      [.]mom$
      [.]mg$
      [.]com\.py$
      [.]af$
      [.]ng$
      [.]ro$
      [.]ar$
      [.]pro$
    '';
    allowlist_fwd_hosts = lib.concatStringsSep "\n" config.services.postfix.networks;
  in ''
    BAD_SUBJECT_BL {
      type = "header";
      header = "subject";
      regexp = true;
      map = "${pkgs.writeText "bad_subj_bl.map" blocked_subjects}";
      description = "Blocklist for common spam subjects";
      score = 8;
    }
    SENDER_TLD_FROM {
      type = "from";
      filter = 'email:domain:tld';
      prefilter = true;
      map = "${pkgs.writeText "bad_tld_bl.map" greylist_tlds}";
      regexp = true;
      description = "Local tld from blocklist";
      action = "greylist";
    }
    WHITELISTED_FWD_HOST {
      type = "ip";
      map = "${pkgs.writeText "allowlist_fwd_hosts" allowlist_fwd_hosts}";
      symbols_set = ["WHITELISTED_FWD_HOST"];
    }
  '';
  services.rspamd.locals."fuzzy_check.conf".text = ''
    rule "mailcow" {
        # Fuzzy storage server list
        servers = "fuzzy.mailcow.email:11445";
        # Default symbol for unknown flags
        symbol = "MAILCOW_FUZZY_UNKNOWN";
        # Additional mime types to store/check
        mime_types = ["application/*"];
        # Hash weight threshold for all maps
        max_score = 100.0;
        # Whether we can learn this storage
        read_only = yes;
        # Ignore unknown flags
        skip_unknown = yes;
        # Hash generation algorithm
        algorithm = "mumhash";
        # Encrypt connection
        encryption_key = "oa7xjgdr9u7w3hq1xbttas6brgau8qc17yi7ur5huaeq6paq8h4y";
        # Map flags to symbols
        fuzzy_map = {
            MAILCOW_FUZZY_DENIED {
                max_score = 10.0;
                flag = 11;
            }
        }
    }
  '';
  services.rspamd.locals."fuzzy_group.conf".text = ''
    symbols = {
        "MAILCOW_FUZZY_UNKNOWN" {
            weight = 0.1;
        }
        "MAILCOW_FUZZY_DENIED" {
            weight = 7.0;
        }
    }
  '';
  services.rspamd.locals."force_actions.conf".text = ''
    rules {
      WHITELIST_FORWARDING_HOST_NO_ACTION {
        action = "no action";
        expression = "WHITELISTED_FWD_HOST";
        require_action = ["reject", "greylist", "soft reject", "add header"];
      }
    }
  '';

  services.rspamd.overrides."actions.conf".text = ''
    add_header = 4;
    greylist = 6;
    reject = 10;
  '';

  users.users.uwsgi.uid = config.ids.uids.uwsgi;
  users.users.uwsgi.group = "uwsgi";
  users.groups.uwsgi.gid = config.ids.gids.uwsgi;
}
