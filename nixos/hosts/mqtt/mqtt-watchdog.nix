{
  pkgs,
  ...
}:

{
  sops.secrets.mqtt_watchdog_environment = {
    sopsFile = ./secrets.yaml;
  };

  systemd.services.mqtt-watchdog = rec {
    description = "MQTT host monitoring watchdog";
    requisite = [ "mosquitto.service" ];
    after = requisite;
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.mqtt-watchdog}/bin/mqtt-watchdog";
      User = "mqtt-watchdog";
      DynamicUser = true;
      Environment = "MQTT_SERVER=localhost";
      EnvironmentFile = "/run/secrets/mqtt_watchdog_environment";
      Restart = "always";
      RestartSec = 60;
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };
}
