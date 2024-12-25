{ config, lib, ... }:

{
  config = {
    networking.nftables.extraInput = lib.mkAfter ''
      ip saddr 185.106.84.29/32 tcp dport 25 accept
      ip6 saddr 2001:67c:20a0:e::29/128 tcp dport 25 accept
    '';

    services.postfix.enable = true;
    services.postfix.domain = "tickets.c3voc.de";
    services.postfix.destination = [ "tickets.c3voc.de" ];
    services.postfix.transport = ''
      tickets.c3voc.de otrs-delivery
    '';
    services.postfix.masterConfig."otrs-delivery".type = "unix";
    services.postfix.masterConfig."otrs-delivery".privileged = true;
    services.postfix.masterConfig."otrs-delivery".chroot = false;
    services.postfix.masterConfig."otrs-delivery".maxproc = 10;
    services.postfix.masterConfig."otrs-delivery".command = "pipe";
    services.postfix.masterConfig."otrs-delivery".args = [
      "flags=Rq"
      "user=${config.services.znuny.user}"
      "null_sender="
      "argv=${config.services.znuny.pkg}/bin/znuny.Console.pl Maint::PostMaster::Read --untrusted --quiet"
    ];
  };
}
