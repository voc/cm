{ lib, config, pkgs, ... }:

let
  mqttHost = "mqtt.c3voc.de";

  voc2mqtt-tools = pkgs.callPackage ./package.nix {};

  voc2mqtt = pkgs.writeShellScriptBin "voc2mqtt" ''
    [[ -n "$DEBUG" ]] && set -x
    set -euo pipefail

    username=$(< /run/secrets/mqtt_username)
    password=$(< /run/secrets/mqtt_password)

    timeout 9 \
        ${lib.getExe' pkgs.mosquitto "mosquitto_pub"} \
        -h ${mqttHost} \
        -p 8883 \
        -u "$username" \
        -P "$password" \
        "$@"
  '';
in

{
  sops.secrets = {
    mqtt_username = {
      sopsFile = ./secrets.yaml;
      mode = "0444";
    };
    mqtt_password = {
      sopsFile = ./secrets.yaml;
      mode = "0444";  # consistency with debian bundlewrap
    };
  };

  environment.systemPackages = [
    voc2mqtt
    voc2mqtt-tools  # ensure voc2alert is in the system PATH.
  ];

  systemd.timers.check_system_and_send_mqtt_message = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "minutely";
      AccuracySec = "1s";
    };
  };

  systemd.services.check_system_and_send_mqtt_message = {
    after = [ "network.target" ];
    requires = [ "network.target" ];
    path = [ voc2mqtt ];
    script = lib.getExe' voc2mqtt-tools "check_system.sh";
    environment.MY_HOSTNAME = "${config.networking.hostName}.${config.networking.domain}";
    serviceConfig.Type = "oneshot";
  };

  systemd.services.send-mqtt-shutdown = {
    after = [ "network.target" ];
    requires = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ voc2mqtt ];
    preStop = lib.getExe' voc2mqtt-tools "alert_shutdown.sh";
    environment.MY_HOSTNAME = "${config.networking.hostName}.${config.networking.domain}";

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStopSec = 5;
    };
  };
}
