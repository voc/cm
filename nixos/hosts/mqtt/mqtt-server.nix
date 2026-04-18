{
  lib,
  pkgs,
  config,
  ...
}:

let
  cfg = config.services.mosquitto;

  # services.mosquitto hardcodes "per_listener_settings true", so we
  # override the entire config file.
  mosquittoConfig = pkgs.writeText "mosquitto.conf" ''
    persistence true
    persistence_location ${cfg.dataDir}
    per_listener_settings false

    log_dest syslog
    log_timestamp false
    log_type information

    allow_anonymous false
    password_file /run/secrets/mqtt_encrypted_passwords

    # Plaintext (needed for viri?)
    listener 1883

    # TLS
    listener 8883
    cafile /srv/mqttcerts/fullchain.pem
    certfile /srv/mqttcerts/cert.pem
    keyfile /srv/mqttcerts/privkey.pem
  '';
in
{
  environment.systemPackages = [ cfg.package ];

  sops.secrets.mqtt_encrypted_passwords = {
    sopsFile = ./secrets.yaml;
    mode = "0600";
    owner = config.users.users.mosquitto.name;
    group = config.users.users.mosquitto.group;
  };

  services.mosquitto.enable = true;
  systemd.services.mosquitto.serviceConfig.ExecStart =
    lib.mkForce "${cfg.package}/bin/mosquitto -c ${mosquittoConfig}";
  systemd.services.mosquitto.serviceConfig.ReadOnlyPaths = "/srv/mqttcerts";

  networking.firewall.allowedTCPPorts = [ 80 443 1883 8883 ];

  users.groups.mqtt-certs.members = [ "mosquitto" "nginx" ];
  security.acme.certs."mqtt.c3voc.de".group = "mqtt-certs";
  services.nginx = {
    enable = true;
    virtualHosts."mqtt.c3voc.de" = {
      forceSSL = true;
      enableACME = true;
      locations."/".return = "307 https://c3voc.de";
    };
  };
}
