{ config, lib, pkgs, ... }:

with lib;

# voc-consul module
#
# Sets up consul for streaming CDN service discovery and key/value storage.
#
let cfg = config.services.voc-consul;
in {
  options = {
    services.voc-consul = {
      enable = mkEnableOption "voc-consul";
      server = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether this node should act as a consul server.
        '';
      };
      webUi = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable the Consul web UI.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    nixpkgs.config.allowUnfree = true;
    services.consul = {
      enable = true;
      webUi = cfg.webUi;
      interface.bind = "nebula";
      extraConfig = let
        consulDomain = builtins.replaceStrings ["."] ["-"] config.networking.domain;
        serverOptions = if cfg.server then {
          server = true;
          bootstrap_expect = 3;
          telemetry = {
            dogstatsd_addr = "localhost:8125";
            disable_hostname = true;
            prometheus_retention_time = "60s";
          };
        } else { server = false; };
      in {
        datacenter = "de";
        node_name = config.networking.hostName + "-" + consulDomain;
        # TODO: derive from servers' addresses
        retry_join = [ "172.23.0.1" "172.23.0.3" "172.23.128.119" ];
        performance = {
          raft_multiplier = 5;
        };
        # make lan-mode behave more like wan-mode
        gossip_lan = {
          gossip_nodes = 4;
          gossip_interval = "500ms";
          probe_timeout = "1s";
          suspicion_mult = 6;
        };
        disable_update_check = true;
      } // serverOptions;
    };
  };
}
