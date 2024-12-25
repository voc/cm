{ config, inputs, ... }:

{

  imports = [
    inputs.authentik-nix.nixosModules.default
  ];

  config = {
    sops.secrets."authentik-token" = {};
    sops.templates."authentik.env".content = ''
      AUTHENTIK_HOST=https://sso.c3voc.de
      AUTHENTIK_TOKEN=${config.sops.placeholder."authentik-token"}
    '';

    services.authentik-ldap.enable = true;
    services.authentik-ldap.environmentFile = config.sops.templates."authentik.env".path;
  };
}
