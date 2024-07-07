{ modulesPath, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/proxmox-image.nix"

    ./plugins.nix
    ./templates.nix
  ];
  config = {
    system.stateVersion = "23.11"; # do not touch

    networking.firewall.allowedTCPPorts = [ 80 ];

    services.dokuwiki.webserver = "nginx";
    services.dokuwiki.sites."wiki.lan.c3voc.de" = {
      enable = true;
      acl = [
        { page = "user:%USER%"; actor = "%USER%"; level = "delete"; }
        { page = "people:%USER%"; actor = "%USER%"; level = "delete"; }

        { page = "3editc3:raumfrage"; actor = "@ALL"; level = "none"; }
        { page = "3editc3:raumfrage"; actor = "@intern"; level = "edit"; }
        { page = "3editc3:raumfrage"; actor = "@user"; level = "edit"; }
        { page = "cccampread5:geld"; actor = "@intern"; level = "edit"; }
        { page = "cccampread5:geld"; actor = "@ALL"; level = "none"; }
        { page = "cccvideoarchive"; actor = "@videoarchive"; level = "edit"; }
        { page = "docu:overview"; actor = "@ALL"; level = "read"; }
        { page = "docu:overview"; actor = "@user"; level = "edit"; }
        { page = "events:33c3:aufbau"; actor = "@ALL"; level = "none"; }
        { page = "events:33c3:aufbau"; actor = "@user"; level = "edit"; }
        { page = "events:33c3:sendezentrum"; actor = "@sendezentrum"; level = "edit"; }
        { page = "events:33c3:sendezentrum"; actor = "@ALL"; level = "none"; }
        { page = "events:33c3:sendezentrum"; actor = "@user"; level = "edit"; }
        { page = "events:33c3:sendezentrum"; actor = "@intern"; level = "edit"; }
        { page = "events:33c3:sendzentrum"; actor = "@ALL"; level = "none"; }
        { page = "events:33c3:sendzentrum"; actor = "@intern"; level = "edit"; }
        { page = "events:33c3:sendzentrum"; actor = "@sendezentrum"; level = "edit"; }
        { page = "events:bitsundbaeumereadupload"; actor = "@fiff"; level = "edit"; }
        { page = "events:event"; actor = "@ALL"; level = "none"; }
        { page = "events:event"; actor = "@user"; level = "edit"; }
        { page = "events:fifconreadupload"; actor = "@fiff"; level = "edit"; }
        { page = "events:rc3:*"; actor = "@user"; level = "upload"; }
        { page = "events:rc3:endpunkte"; actor = "@none"; level = "none"; }
        { page = "events:rc3:endpunkte"; actor = "@ALL"; level = "none"; }
        { page = "events:rc3:endpunkte"; actor = "@user"; level = "read"; }
        { page = "events:rc3:kanal-howto"; actor = "@ALL"; level = "none"; }
        { page = "events:rc3:kanal-howto"; actor = "@user"; level = "edit"; }
        { page = "intern:*"; actor = "@ALL"; level = "none"; }
        { page = "intern:*"; actor = "@intern"; level = "upload"; }
        { page = "intern:voccon"; actor = "@user"; level = "edit"; }
        { page = "meetings:meeting"; actor = "@ALL"; level = "none"; }
        { page = "meetings:meeting"; actor = "@user"; level = "edit"; }
        { page = "people:*"; actor = "@ALL"; level = "none"; }
        { page = "people:*"; actor = "@intern"; level = "edit"; }
        { page = "people:*"; actor = "@user"; level = "edit"; }
        { page = "subtitles:*"; actor = "@none"; level = "edit"; }
        { page = "subtitles:*"; actor = "@subtitles"; level = "upload"; }
      ];
    };
  };
}
