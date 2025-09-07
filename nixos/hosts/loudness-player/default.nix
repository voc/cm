{ config, lib, modulesPath, pkgs, ... }:


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
  imports = [
    "${modulesPath}/installer/cd-dvd/iso-image.nix"
    "${modulesPath}/installer/scan/not-detected.nix"
  ];
  config = {

    # EFI booting
    isoImage.makeEfiBootable = true;

    # USB booting
    isoImage.makeUsbBootable = true;

    # Much faster than xz
    isoImage.squashfsCompression = lib.mkDefault "zstd";

    isoImage.appendToMenuLabel = " Loudness Monitor";

    isoImage.efiSplashImage = ./splash-efi.png;
    isoImage.splashImage = ./splash-legacy.png;
    isoImage.storeContents = lib.mkForce [ config.system.build.toplevel ] ;

    system.stateVersion = "25.05"; # do not touch

    # Results from hardware scan on Modula hardware
    boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usbhid" "usb_storage" "sd_mod" "sdhci_pci" "xfs" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-intel" ];
    boot.extraModulePackages = [ ];

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    fileSystems."/" =
      { device = "/dev/disk/by-label/nixos";
        fsType = "xfs";
      };

    fileSystems."/boot" =
      { device = "/dev/disk/by-label/boot";
        fsType = "vfat";
        options = [ "fmask=0022" "dmask=0022" ];
      };

    # System configuration

    users.groups.voc = {};
    users.users.voc = {
      isNormalUser = true;
      group = "voc";
      hashedPassword = "$2y$10$L4ri1ntzWk6LD4zndOB4oe5ErZfJE2h/HmfKRYw5/.FUrqKIJDxN.";
    };

    services.xserver.enable = true;
    services.xserver.displayManager.autoLogin.enable = true;
    services.xserver.displayManager.autoLogin.user = "voc";
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

    nixpkgs.config.packageOverrides = pkgs: {
      intel-vaapi-driver = pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
    };
    hardware.opengl = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver # LIBVA_DRIVER_NAME=iHD
        intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
        libvdpau-va-gl
      ];
    };
    environment.sessionVariables = { LIBVA_DRIVER_NAME = "iHD"; };

  };
}

