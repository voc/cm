{
  config,
  lib,
  pkgs,
  ...
}:

let
  voc2alert = lib.getExe' pkgs.voc2mqtt-tools "voc2alert";
  mdadmMqttProgram = pkgs.writeShellScript "mdadm-event-to-mqtt" ''
    set -euo pipefail

    event="''${1:-unknown}"
    dev="''${2:-unknown}"
    related_dev="''${3:-}"

    case "$event" in
      DeviceDisappeared|Fail|FailSpare|DegradedArray|SparesMissing)
        level="error"
        ;;
      MoveSpare|RebuildStarted|Rebuild[0-9]*|RecoveryStarted|Recovery[0-9]*|ResyncStarted|Resync[0-9]*)
        level="warn"
        ;;
      RebuildFinished|RecoveryFinished|ResyncFinished|SpareActive|CheckStarted|Check[0-9]*)
        level="info"
        ;;
      NewArray|CheckFinished|WorkingArray)
        # uninteresting events, don't alert
        exit 0
        ;;
      *)
        level="info"
        ;;
    esac

    if [ -n "$related_dev" ]; then
        ${voc2alert} "$level" "mdadm" "$event on $dev (related: $related_dev)"
    else
        ${voc2alert} "$level" "mdadm" "$event on $dev"
    fi'';
in
{
  config = lib.mkIf config.boot.swraid.enable {
    boot.swraid.mdadmConf = lib.mkAfter ''
      PROGRAM ${mdadmMqttProgram}
    '';
  };
}
