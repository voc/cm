{ lib, config, pkgs, ... }:

let
  mpvWrapper = pkgs.writeShellScript "mpv-wrapper" ''
    set -u
    stream="$1"

    stream_url="rtmp://ingest2.c3voc.de/relay/''${stream}_loudness"
    uid=$(id -u)

    while sleep 1; do
      ${pkgs.mpv}/bin/mpv --title="$stream" "$stream_url" \
        --no-cache --hwdec==vaapi --mute \
        --input-ipc-server="/run/user/$uid/mpv-$stream.sock"
    done
  '';

  i3status = pkgs.writeText "i3-status" ''
    general {
        output_format = "i3bar"
        colors = true
        interval = 1
    }

    order += "ipv6"
    order += "ethernet _first_"
    order += "cpu_temperature 0"
    order += "cpu_usage"
    order += "memory"
    order += "tztime berlin"

    ethernet _first_ {
        format_up = "ETH: %ip (%speed)"
        format_down = "ETH: down"
    }

    cpu_temperature 0 {
        format = "TEMP: %degrees °C"
        path = "/sys/devices/platform/coretemp.0/temp1_input"
    }

    memory {
        format = "MEM: %percentage_used used, %percentage_free free, %percentage_shared shared"
        threshold_degraded = "10%"
        format_degraded = "MEMORY: %free"
    }

    tztime berlin {
        format = "%Y-%m-%d %H:%M:%S %Z"
        timezone = "Europe/Berlin"
    }

    cpu_usage {
        format = "CPU: %usage"
    }
  '';

  i3config = pkgs.writeText "i3-config" ''
    # i3 config file (v4)
    default_border none

    bar {
      mode dock
      workspace_buttons off
      status_command i3status -c ${i3status}
    }

    exec --no-startup-id "i3-msg 'workspace 1; append_layout ${i3layout}'"

    exec ${mpvWrapper} s1
    exec ${mpvWrapper} s2
    exec ${mpvWrapper} s3
    exec ${mpvWrapper} s4
    exec ${mpvWrapper} s5
    exec ${mpvWrapper} s6
  '';

  i3layout = pkgs.writeText "i3-layout" ''
    {
      "layout": "splitv",
      "type": "con",
      "nodes": [
        {
          "layout": "splith",
          "type": "con",
          "nodes": [
            {"swallows": [{"title": "s1"}]},
            {"swallows": [{"title": "s2"}]},
            {"swallows": [{"title": "s3"}]}
          ]
        },
        {
          "layout": "splith",
          "type": "con",
          "nodes": [
            {"swallows": [{"title": "s4"}]},
            {"swallows": [{"title": "s5"}]},
            {"swallows": [{"title": "s6"}]}
          ]
        }
      ]
    }
  '';

in
{
  services.xserver.enable = true;
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "voc";
  services.xserver.displayManager.xserverArgs = [ "-nocursor" ];
  services.xserver.displayManager.sessionCommands = ''
  '';
  services.xserver.windowManager.i3.enable = true;
  services.xserver.windowManager.i3.extraPackages = [
    pkgs.i3status
    pkgs.xdotool
  ];
  services.xserver.windowManager.i3.extraSessionCommands = ''
    xset -dpms
    xset s off
  '';
  services.xserver.windowManager.i3.configFile = i3config;
}
