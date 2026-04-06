{ config, lib, options, pkgs, ... }:

# like system.autoUpgrade but using colmena

let
  cfg = config.system.autoColmena;
in
{
  options.system.autoColmena = {
    enable = lib.mkEnableOption "autoColmena";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.colmena;
      description = "Colmena package to use for the upgrade.";
    };

    flake = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "github:voc/cm?dir=nixos";
      description = "Flake URI of the Colmena configuration to build.";
    };

    dates = lib.mkOption {
      type = lib.types.str;
      default = "03:30";
      example = "daily";
      description = "systemd calendar spec for scheduling the upgrade unit.";
    };
  };

  config = lib.mkIf cfg.enable ({
    assertions = [
      {
        assertion = cfg.flake != null;
        message = "The option 'system.autoColmena.flake' option must not be null.";
      }
    ];

    systemd.timers.colmena-upgrade = {
      wantedBy = [ "timers.target" ];
      timerConfig.OnCalendar = cfg.dates;
    };

    systemd.services.colmena-upgrade = rec {
      description = "System upgrade with Colmena.";
      after = [ "network-online.target" ];
      wants = after;
      restartIfChanged = false;
      serviceConfig.Type = "oneshot";
      path = [
        config.nix.package.out
      ];
      script = "${lib.getExe' cfg.package "colmena"} -f '${cfg.flake}' apply-local -v switch";
    };
  } // lib.optionalAttrs (options ? deployment) {
    deployment.allowLocalDeployment = true;
  });
}
