{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:

let
  replace = config.sops.placeholder;
  template = config.sops.templates."viri-matrix.toml";

  system = pkgs.stdenv.hostPlatform.system;
  package = inputs.viri-matrix.packages."${system}".default;
in
{
  sops = {
    templates."viri-matrix.toml" = {
      content = ''
        help = """help is available on the C3VOC wiki: [chat#usage_of_irc_bots](https://c3voc.de/wiki/chat#usage_of_irc_bots)

        You can also reply to messages with "silence for <duration> / until <time>" or
        react with 🔇 for a quick 15min timeout."""

        [mqtt]
        host = "mqtt.c3voc.de"
        port = 8883
        ssl = true
        forward_topic = "/voc/alert-viri"

        user = "${replace.viri_mqtt_user}"
        password = "${replace.viri_mqtt_password}"

        [matrix]
        homeserver = "https://matrix.c3voc.de"
        user_id = "${replace.viri_matrix_userid}"
        password = "${replace.viri_matrix_password}"
        room_id = "${replace.viri_matrix_roomid}"

        [database]
        url = "postgresql+psycopg2://viri-matrix@/viri-matrix"
      '';
    };

    secrets = builtins.listToAttrs (
      map
        (
          n:
          lib.nameValuePair n {
            sopsFile = ./secrets.yaml;
          }
        )
        [
          "viri_matrix_userid" # should have ratelimiting disabled
          "viri_matrix_password"
          "viri_matrix_roomid"
          "viri_mqtt_user"
          "viri_mqtt_password"
        ]
    );
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "viri-matrix" ];
    ensureUsers = [
      {
        name = "viri-matrix";
        ensureDBOwnership = true;
      }
    ];
  };

  systemd.services.viri-matrix = {
    description = "MQTT alert bot for Matrix";
    after = [
      "network-online.target"
      "matrix-synapse.service"
      "postgresql.service"
    ];
    wants = [ "network-online.target" ];
    requisite = [
      "matrix-synapse.service"
      "postgresql.service"
    ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = "${package}/bin/viri-matrix";
      Restart = "always";
      RestartSec = "10";
      DynamicUser = true;
      User = "viri-matrix";
      LoadCredential = "config.toml:${template.path}";
      Environment = "CONFIG_PATH=%d/config.toml";
    };
  };
}
