{ lib, config, pkgs, ... }:

let
  mpvWrapper = pkgs.writeShellScript "mpv-wrapper" ''
    while true
    do
      ${pkgs.mpv}/bin/mpv "$@" --no-cache --hwdec==vaapi
      ${pkgs.coreutils}/bin/sleep 1
    done
  '';

  i3layoutfixer = pkgs.writeShellScript "i3-layout-fixer" ''
    WINDOWS=$(xdotool search --all --onlyvisible --desktop $(xprop -notype -root _NET_CURRENT_DESKTOP | cut -c 24-) "" 2>/dev/null)

    for window in $WINDOWS; do
      xdotool windowunmap "$window"
    done

    i3-msg "append_layout ${i3layout}"

    for window in $WINDOWS; do
      xdotool windowmap "$window"
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

    bindsym Mod4+Control+Shift+r exec ${i3layoutfixer}

    exec ${mpvWrapper} --title=s1 rtmp://ingest2.c3voc.de/relay/s1_loudness
    exec ${mpvWrapper} --title=s2 rtmp://ingest2.c3voc.de/relay/s2_loudness
    exec ${mpvWrapper} --title=s3 rtmp://ingest2.c3voc.de/relay/s3_loudness
    exec ${mpvWrapper} --title=s4 rtmp://ingest2.c3voc.de/relay/s4_loudness
    exec ${mpvWrapper} --title=s5 rtmp://ingest2.c3voc.de/relay/s5_loudness
    exec ${mpvWrapper} --title=s6 rtmp://ingest2.c3voc.de/relay/s6_loudness
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
