{ lib, modulesPath, pkgs, ... }:


let
  mpvWrapper = pkgs.writeShellScript "mpv-wrapper" ''
    while true
    do
      ${pkgs.mpv}/bin/mpv "$@" --no-cache --hwdec==vaapi
      ${pkgs.coreutils}/bin/sleep 1
    done
  '';

  i3config = pkgs.writeText "i3-config" ''
    # i3 config file (v4)
    default_border none

    bar {
      mode invisible
    }

    exec --no-startup-id "i3-msg 'workspace 1; append_layout ${i3layout}'"

    exec ${mpvWrapper} --title=s1 rtmp://ingest2.c3voc.de/relay/s1_loudness
    exec ${mpvWrapper} --title=s3 rtmp://ingest2.c3voc.de/relay/s3_loudness
    exec ${mpvWrapper} --title=s6 rtmp://ingest2.c3voc.de/relay/s6_loudness
    exec ${mpvWrapper} --title=emfa rtmp://ingest2.c3voc.de/relay/emf_stagea_loudness
    exec ${mpvWrapper} --title=emfb rtmp://ingest2.c3voc.de/relay/emf_stageb_loudness
    exec ${mpvWrapper} --title=emfc rtmp://ingest2.c3voc.de/relay/emf_stagec_loudness
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
            {"swallows": [{"title": "s3"}]},
            {"swallows": [{"title": "s6"}]}
          ]
        },
        {
          "layout": "splith",
          "type": "con",
          "nodes": [
            {"swallows": [{"title": "emfa"}]},
            {"swallows": [{"title": "emfb"}]},
            {"swallows": [{"title": "emfc"}]}
          ]
        }
      ]
    }
  '';
in
{
  imports = [
    "${modulesPath}/installer/cd-dvd/iso-image.nix"
  ];
  config = {

    # EFI booting
    isoImage.makeEfiBootable = true;

    # USB booting
    isoImage.makeUsbBootable = true;

    # Much faster than xz
    isoImage.squashfsCompression = lib.mkDefault "zstd";

    system.stateVersion = "23.11"; # do not touch

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

