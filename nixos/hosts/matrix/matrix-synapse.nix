{
  lib,
  pkgs,
  config,
  ...
}:

let
  homeserverDomain = "c3voc.de";
  synapseDomain = "matrix.c3voc.de";

  mkJsonLocation = payload: {
    extraConfig = ''
      default_type application/json;
      add_header Access-Control-Allow-Origin *;
    '';
    return = "200 '${builtins.toJSON payload}'";
  };
in
{
  sops.secrets.registration_shared_secret = {
    sopsFile = ./secrets.yaml;
    mode = "0600";
    owner = config.users.users.matrix-synapse.name;
    group = config.users.users.matrix-synapse.group;
  };

  # matrix-synapse insists on the database collation being set to C,
  # so the synapse database needs to be created manually with
  # "createdb -O matrix-synapse -l C -T template0 matrix-synapse"
  # instead of using ensureDatabases.
  services.postgresql.enable = true;

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.nginx = {
    enable = true;
    virtualHosts."${synapseDomain}" = {
      default = true;
      enableACME = true;
      forceSSL = true;

      locations =
        let
          synapseListener = "http://127.0.0.1:8008";
        in
        {
          "/".return = "307 https://c3voc.de/wiki/chat";
          "/_matrix".proxyPass = synapseListener;
          "/_matrix".extraConfig = "client_max_body_size 50M;";
          "/_synapse/client".proxyPass = synapseListener;

          "/.well-known/matrix/client" = mkJsonLocation {
            "m.homeserver"."base_url" = "https://${synapseDomain}";
          };
          "/.well-known/matrix/server" = mkJsonLocation {
            "m.server" = "${synapseDomain}:443";
          };
        };
    };
  };

  services.matrix-synapse = {
    enable = true;

    # don't log *every* incoming http access
    log.loggers."synapse.access.http".level = "WARNING";
    log.loggers."synapse.federation.transport.server.federation".level = "WARNING";

    settings = {
      server_name = homeserverDomain;
      enable_registration = false;
      report_stats = false;
      public_baseurl = "https://${synapseDomain}/";

      # default listener config: client and federation on loopback port 8008

      database.name = "psycopg2";

      event_cache_size = "1M";
      allow_guest_access = false;
      password_config.enabled = true;
    };

    extraConfigFiles = [
      "/run/secrets/registration_shared_secret"
    ];
  };
}
