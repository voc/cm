{ config, lib, pkgs, ... }:

with lib;

# voc-nebula module
#
# Creates an overlay network between rz-nodes using Nebula.
#
let cfg = config.services.voc-nebula;
  fqdn = config.networking.hostName + "." + config.networking.domain;
in {
  options = {
    services.voc-nebula = {
      enable = mkEnableOption "voc-nebula";
      isLighthouse = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether this node should act as a lighthouse.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      nebula
    ];
    sops.secrets = {
      nebula_ca_cert = {
        sopsFile = ./secrets/ca.yaml;
        key = "cert";
        owner = "nebula-nebula";
      };
      nebula_key = {
        sopsFile = ./secrets + "/${fqdn}.yaml";
        key = "key";
        owner = "nebula-nebula";
      };
      nebula_cert = {
        sopsFile = ./secrets + "/${fqdn}.yaml";
        key = "cert";
        owner = "nebula-nebula";
      };
    };
    services.nebula.networks.nebula = {
      enable = true;
      isLighthouse = cfg.isLighthouse;
      cert = config.sops.secrets.nebula_cert.path;
      key = config.sops.secrets.nebula_key.path;
      ca = config.sops.secrets.nebula_ca_cert.path;
      listen.host = "[::]"; # listen on both v4 and v6
      # todo: derive from lighthouses
      lighthouses = [ "172.23.0.1" "172.23.0.3" "172.23.128.119" ];
      staticHostMap = {
        "172.23.0.1" = ["185.106.84.35:4242" "[2001:67c:20a0:e::169]:4242"];
        "172.23.0.3" = ["193.203.16.35:4242" "[2a00:c380:c101:2800::35]:4242"];
        "172.23.128.119" = ["62.176.246.169:4242" "[2a01:581:b::15]:4242"];
      };
      firewall.outbound = [{
        host="any";
        port="any";
        proto="any";
      }];
      settings = {
        tun = {
          dev = "nebula";
          drop_local_broadcast = true;
          drop_multicast = true;
        };
        stats = {
          type = "prometheus";
          listen = "127.0.0.1:2343";
          path = "/metrics";
          namespace = "nebula";
          subsystem = "";
          interval = "10s";
          message_metrics = true;
          lighthouse_metrics = false;
        };
        firewall.conntrack.tcp_timeout = "3h";
        punchy.punch = true;
      };
    };
    services.telegraf.extraConfig = {
      inputs = {
        prometheus = {
          urls = [ "http://localhost:2343/metrics" ];
          metric_version = 1;
          tags = {
            job = "nebula";
          };
        };
      };
    };
  };
}
