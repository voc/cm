{ config, lib, pkgs, ... }:

{
  sops = {
    secrets.netbox_initial_password = {
      owner = "netbox";
    };
    secrets.netbox_auth_client_id = {
      owner = "netbox";
    };
    secrets.netbox_auth_client_secret = {
      owner = "netbox";
    };
  };



  services.netbox = {
    enable = true;
    listenAddress = "[::1]";
    secretKeyFile = config.sops.secrets.netbox_initial_password.path;
    package = pkgs.netbox.overrideAttrs (attrs: {
      installPhase = attrs.installPhase + ''
        ln -sf ${./custom_pipeline.py} $out/opt/netbox/netbox/netbox/custom_pipeline.py
      '';
    });


    extraConfig = ''
      import os
      # NetBox settings
      REMOTE_AUTH_ENABLED = True
      REMOTE_AUTH_BACKEND = 'social_core.backends.open_id_connect.OpenIdConnectAuth'

      # python-social-auth configuration
      SOCIAL_AUTH_OIDC_SCOPE = ['openid', 'profile', 'email', 'groups', 'netbox']
      SOCIAL_AUTH_OIDC_JWT_ALGORITHMS = ['RS256', 'HS256']
      SOCIAL_AUTH_OIDC_ENDPOINT = 'https://sso.c3voc.de/application/o/netbox'
      with open('${config.sops.secrets.netbox_auth_client_id.path}', "r") as id_file:
        SOCIAL_AUTH_OIDC_KEY = id_file.readline()
      with open('${config.sops.secrets.netbox_auth_client_secret.path}', "r") as secret_file:
        SOCIAL_AUTH_OIDC_SECRET = secret_file.readline()
      LOGOUT_REDIRECT_URL = 'https://sso.c3voc.de/application/o/netbox/end-session/'

      SOCIAL_AUTH_PIPELINE = (
          ###################
          # Default pipelines
          ###################

          # Get the information we can about the user and return it in a simple
          # format to create the user instance later. In some cases the details are
          # already part of the auth response from the provider, but sometimes this
          # could hit a provider API.
          'social_core.pipeline.social_auth.social_details',

          # Get the social uid from whichever service we're authing thru. The uid is
          # the unique identifier of the given user in the provider.
          'social_core.pipeline.social_auth.social_uid',

          # Verifies that the current auth process is valid within the current
          # project, this is where emails and domains whitelists are applied (if
          # defined).
          'social_core.pipeline.social_auth.auth_allowed',

          # Checks if the current social-account is already associated in the site.
          'social_core.pipeline.social_auth.social_user',

          # Make up a username for this person, appends a random string at the end if
          # there's any collision.
          'social_core.pipeline.user.get_username',

          # Send a validation email to the user to verify its email address.
          # Disabled by default.
          # 'social_core.pipeline.mail.mail_validation',

          # Associates the current social details with another user account with
          # a similar email address. Disabled by default.
          'social_core.pipeline.social_auth.associate_by_email',

          # Create a user account if we haven't found one yet.
          'social_core.pipeline.user.create_user',

          # Create the record that associates the social account with the user.
          'social_core.pipeline.social_auth.associate_user',

          # Populate the extra_data field in the social record with the values
          # specified by settings (and the default ones like access_token, etc).
          'social_core.pipeline.social_auth.load_extra_data',

          # Update the user record with any changed info from the auth service.
          'social_core.pipeline.user.user_details',

          ###################
          # Custom pipelines
          ###################
          # Set authentik Groups
          'netbox.custom_pipeline.add_groups',
          'netbox.custom_pipeline.remove_groups',
          # Set Roles
          'netbox.custom_pipeline.set_roles'
      )

      LOGIN_REQUIRED = False
      EXEMPT_VIEW_PERMISSIONS = ['*']
    '';
  };

  services.nginx.group = "netbox";
  security.acme.certs."netbox.c3voc.de".group = "netbox";
  services.nginx.virtualHosts."netbox.c3voc.de" = {
    forceSSL = true;
    enableACME = true;
    locations."/".proxyPass = "http://localhost:8001";
    locations."/static".root = "${config.services.netbox.dataDir}";
  };
}
