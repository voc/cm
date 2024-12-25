{ config, lib, modulesPath, pkgs, ... }:

with lib;

let
in
{
  imports = [
    "${modulesPath}/virtualisation/proxmox-image.nix"

    ./authentik.nix
    ./mail.nix
    ./znuny.nix
  ];
  config = {
    system.stateVersion = "23.11"; # do not touch

    sops.secrets."ldap-bind-password".owner = "znuny";

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

      $Self->{'SendmailNotificationEnvelopeFrom'} = 'znuny@c3voc.de';

      $Self->{'SendmailModule'} = 'Kernel::System::Email::SMTP';
      $Self->{'SendmailModule::Host'} = 'mail.c3voc.de';
      $Self->{'SendmailModule::Port'} = '25';
      $Self->{'SendmailModule::AuthUser'} = "";
      $Self->{'SendmailModule::AuthPassword'} = "";

      $Self->{CheckMXRecord} = 0;

      $Self->{AuthModule} = 'Kernel::System::Auth::HTTPBasicAuth';
      $Self->{LogoutURL} = 'https://sso.c3voc.de/';

      $Self->{'AuthSyncModule'} = 'Kernel::System::Auth::Sync::LDAP';
      $Self->{'AuthSyncModule::LDAP::Host'} = 'localhost';
      $Self->{'AuthSyncModule::LDAP::BaseDN'} = 'dc=znuny,dc=c3voc,dc=de';
      $Self->{'AuthSyncModule::LDAP::UID'} = 'cn';
      $Self->{'AuthSyncModule::LDAP::AlwaysFilter'} = '(objectclass=user)';
      $Self->{'AuthSyncModule::LDAP::GroupDN'} = 'cn=voc,ou=groups,dc=znuny,dc=c3voc,dc=de';
      $Self->{'AuthSyncModule::LDAP::SearchUserDN'} = 'cn=znuny-ldap-bind,ou=users,dc=znuny,dc=c3voc,dc=de';
      use File::Slurper;
      $Self->{'AuthSyncModule::LDAP::SearchUserPw'} = File::Slurper::read_text('${config.sops.secrets."ldap-bind-password".path}');
      $Self->{'AuthSyncModule::LDAP::Params'} = {
          port    => 3389,
      };
      $Self->{'AuthSyncModule::LDAP::AccessAttr'} = 'member';
      $Self->{'AuthSyncModule::LDAP::UserAttr'} = 'DN';
      $Self->{'AuthSyncModule::LDAP::UserSyncInitialGroups'} = [
          'users',
      ];
      $Self->{'AuthSyncModule::LDAP::UserSyncMap'} = {
          UserFirstname => ['givenName', 'cn', '_'],
          UserLastname  => ['sn', '_'],
          UserEmail     => 'mail',
      };
      $Self->{'AuthSyncModule::LDAP::UserSyncGroupsDefinition'} = {
          # ldap group
          'cn=znuny-admin,ou=groups,dc=znuny,dc=c3voc,dc=de' => {
              # otrs group
              'admin' => {
                  rw => 1,
                  ro => 1,
              },
          },
          'cn=voc,ou=groups,dc=znuny,dc=c3voc,dc=de' => {
              'users' => {
                  rw => 1,
                  ro => 1,
              },
          },
          'cn=znuny-test-queue,ou=groups,dc=znuny,dc=c3voc,dc=de' => {
              'znuny-queue' => {
                  rw => 1,
                  ro => 1,
              },
          },
      };
      $Self->{'AuthSyncModule::LDAP::UserSyncRolesDefinition'} = {
      };


    '';

    services.nginx.enable = true;
    services.nginx.virtualHosts."tickets.c3voc.de" = mkMerge [
      {
        forceSSL = true;
        enableACME = true;
        locations."/outpost.goauthentik.io" = {
          proxyPass = "https://sso.c3voc.de/outpost.goauthentik.io";
          extraConfig = ''
            proxy_set_header        Host $host;
            proxy_set_header        X-Origin-URI $request_uri;
            proxy_set_header        X-Original-URL $scheme://$http_host$request_uri;
            add_header              Set-Cookie $auth_cookie;
            auth_request_set        $auth_cookie $upstream_http_set_cookie;
            proxy_pass_request_body off;
            proxy_set_header        Content-Length "";
          '';
        };
        locations."~ ^/znuny/(.*\\.pl)(/.*)?$".extraConfig = mkBefore ''
          auth_request     /outpost.goauthentik.io/auth/nginx;
          auth_request_set $auth_cookie $upstream_http_set_cookie;
          error_page       401 = @goauthentik_proxy_signin;
          add_header       Set-Cookie $auth_cookie;

          auth_request_set $authentik_username $upstream_http_x_authentik_username;

          fastcgi_param REMOTE_USER $authentik_username;
        '';
        locations."@goauthentik_proxy_signin".extraConfig = ''
          internal;
          add_header Set-Cookie $auth_cookie;
          return 302 /outpost.goauthentik.io/start?rd=$scheme://$http_host$request_uri;
        '';
      }
      config.services.znuny.nginxVirtualHostConfig
    ];
  };
}
