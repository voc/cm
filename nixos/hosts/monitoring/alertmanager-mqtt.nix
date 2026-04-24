{
  config,
  lib,
  inputs,
  ...
}:

let
  package = inputs.alertmanager-mqtt.defaultPackage.x86_64-linux;
in
{
  sops.secrets.alertmanager_mqtt = {
    sopsFile = ./secrets.yaml;
    key = "alertmanager_mqtt";
  };
  systemd.services.alertmanager-mqtt = {
    description = "Alertmanager MQTT Forwarder";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      EnvironmentFile = config.sops.secrets.alertmanager_mqtt.path;
      ExecStart = "${package}/bin/alertmanager-mqtt";
      Restart = "on-failure";
      DynamicUser = true;
    };
    restartTriggers = [ config.sops.secrets.alertmanager_mqtt.path ];
  };
}
