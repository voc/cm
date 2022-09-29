{ config, pkgs, lib, ... }:

with lib;

let cfg = config.services.fieldpoc.dhcp;
in {
  options.services.fieldpoc.dhcp = {
    enable = mkEnableOption "fieldpoc-dhcp";
    interface = mkOption {
      type = types.str;
    };
    subnet = mkOption {
      type = types.str;
    };
    pool = mkOption {
      type = types.str;
    };
    router = mkOption {
      type = types.str;
    };
    dnsServers = mkOption {
      type = types.str;
    };
    omm = mkOption {
      type = types.str;
    };
    reservations = mkOption {
      type = with types; listOf (submodule {
        options = {
          name = mkOption {
            type = types.str;
          };
          macAddress = mkOption {
            type = types.str;
          };
          ipAddress = mkOption {
            type = types.str;
          };
        };
      });
      default = [];
    };
  };

  config = mkIf cfg.enable {
    services.kea.dhcp4 = {
      enable = true;
      settings = {
        interfaces-config = {
          interfaces = [ cfg.interface ];
        };
        option-def = [
          {
            space = "dhcp4";
            name = "vendor-encapsulated-options";
            code = 43;
            type = "empty";
            encapsulate = "sipdect";
          }
          {
            space = "sipdect";
            name = "ommip1";
            code = 10;
            type = "ipv4-address";
          }
          {
            space = "sipdect";
            name = "ommip2";
            code = 19;
            type = "ipv4-address";
          }
          {
            space = "sipdect";
            name = "syslogip";
            code = 14;
            type = "ipv4-address";
          }
          {
            space = "sipdect";
            name = "syslogport";
            code = 15;
            type = "int16";
          }
          {
            space = "dhcp4";
            name = "magic_str";
            code = 224;
            type = "string";
          }
        ];

        subnet4 = [
          {
            subnet = cfg.subnet;
            pools = [
              {
                pool = cfg.pool;
              }
            ];
            option-data = [
              {
                name = "routers";
                data = cfg.router;
              }
              {
                name = "domain-name-servers";
                data = cfg.dnsServers;
              }
              {
                name = "vendor-encapsulated-options";
              }
              {
                space = "sipdect";
                name = "ommip1";
                data = cfg.omm;
              }
              {
                name = "magic_str";
                data = "OpenMobilitySIP-DECT";
              }
            ];

            reservations = map (r: {
              hostname = r.name;
              hw-address = r.macAddress;
              ip-address = r.ipAddress;
              option-data = [
                {
                  name = "host-name";
                  data = r.name;
                }
              ];
            }) cfg.reservations;
          }
        ];
      };
    };
  };
}
