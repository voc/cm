{ config, lib, pkgs, ... }:

with lib;

# srtrelay module
#
# SRT relay server for distributing media streams to multiple clients
#
let cfg = config.services.srtrelay;
  configFile = pkgs.writeText "config.toml" ''
    [app]
    # Relay listen address
    addresses = ["[::]:1337"]
    publicAddress = "${config.networking.hostName}.${config.networking.domain}:1337"

    # SRT protocol latency in ms
    # This should be a multiple of your expected RTT because SRT needs some time
    # to send and receive acknowledgements and retransmits to be effective.
    #latency = 300

    # Relay buffer size in bytes, 384000 -> 1 second @ 3Mbits
    # This determines the maximum delay tolerance for connected clients.
    # Clients which are more than buffersize behind the live edge are disconnected.
    #buffersize = 384000
    buffersize = 6400000

    syncClients = true

    [api]
    # Set to false to disable the API endpoint
    #enabled = true

    # API listening address
    address = "0.0.0.0:8084"

    [auth]
    # Choose between available auth types (static and http)
    # for further config options see below
    type = "http"

    [auth.static]
    # Streams are authenticated using a static list of allowed streamids
    # Each pattern is matched to the client streamid
    # in the form of <mode>/<stream-name>/<password>
    # Allows using * as wildcard (will match across slashes)
    #allow = ["*", "publish/foo/bar", "play/*"]

    [auth.http]
    # Streams are authenticated using HTTP POST calls against this URL
    # Should be compatible to nginx-rtmp on_publish/on_subscribe directives
    url = "http://localhost:8080/publish"

    # auth timeout duration
    #timeout = "1s"

    # Value of the 'app' form-field to send in the POST request
    # Needed for compatibility with the RTMP-application field
    #application = "stream"

    # Key of the form-field to send the stream password in
    #passwordParam = "auth"
  '';
in {
  options = {
    services.srtrelay = {
      enable = mkEnableOption "srtrelay";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      srtrelay
    ];
    systemd.services.srtrelay = {
      after = [ "consul.service" ];
      requires = [ "consul.service" ];
      serviceConfig = {
        ExecStart = "${pkgs.srtrelay}/bin/srtrelay --config ${configFile}";
      };
      wantedBy = [ "multi-user.target" ];
      restartIfChanged = true;
      restartTriggers = [ configFile ];
    };
  };
}

