{ config, lib, modulesPath, pkgs, ... }:

with lib;

let
in
{
  imports = [
    "${modulesPath}/virtualisation/proxmox-image.nix"

    ./znuny.nix
  ];
  config = {
    system.stateVersion = "23.11"; # do not touch

    sops.secrets."znuny_mail_password".owner = "znuny";

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

    services.znuny.enable = true;
    services.znuny.prefork = 4;
    services.znuny.extraConfig = ''
      $Self->{FQDN} = '${config.networking.fqdn}';

      $Self->{AdminEmail} = 'voc@c3voc.de';

      $Self->{Organization} = 'c3voc';

      $Self->{'SendmailModule'} = 'Kernel::System::Email::SMTPTLS';
      $Self->{'SendmailModule::Host'} = 'mail.c3voc.de';
      $Self->{'SendmailModule::Port'} = '565';
      $Self->{'SendmailModule::AuthUser'} = 'znuny';
      use File::Slurper 'read_text';
      $Self->{'SendmailModule::AuthPassword'} = read_text('${config.sops.secrets."znuny_mail_password".path}');
    '';

    services.nginx.enable = true;
    services.nginx.virtualHosts."tickets.c3voc.de" = {
      forceSSL = true;
      enableACME = true;
    } // config.services.znuny.nginxVirtualHostConfig;
  };
}
