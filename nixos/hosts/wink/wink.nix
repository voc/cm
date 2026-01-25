{ config, lib, pkgs, ... }:

{
  services.wink = {
    enable = true;
    port = 3000;
    environment = "production";
    workers = 2;
    threads = "5";
    solidQueue.enable = true;
    domain = "wink.c3voc.de";
    enableACME = true;
    extraEnvironment = {
      # MQTT_HOST = "mqtt.c3voc.de";
      # MQTT_PORT = "1883";
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "voc@c3voc.de";
  };
}
