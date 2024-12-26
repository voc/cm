{ config, lib, modulesPath, pkgs, ... }:

with lib;

let
  cfg = config.profiles.stream-player;
  mpvWrapper = pkgs.writeShellScript "mpv-wrapper" ''
    while true
    do
      ${pkgs.mpv}/bin/mpv "$(cat /iso/boot/stream.txt)" --no-cache --hwdec==vaapi
      ${pkgs.coreutils}/bin/sleep 1
    done
  '';

  i3config = pkgs.writeText "i3-config" ''
    # i3 config file (v4)
    default_border none

    bar {
      mode invisible
    }

    exec ${mpvWrapper}
  '';
in
{
  options.profiles.stream-player = {
    enable = mkEnableOption "Enable stream-player profile";
    defaultStream = mkOption {
      type = types.str;
      default = "tcp://encoder6.lan.c3voc.de:11100";
    };
  };

  imports = [
    "${modulesPath}/installer/cd-dvd/iso-image.nix"
  ];
  config = mkIf cfg.enable {

    # EFI booting
    isoImage.makeEfiBootable = true;

    # USB booting
    isoImage.makeUsbBootable = true;

    # Much faster than xz
    isoImage.squashfsCompression = lib.mkDefault "zstd";

    isoImage.prependToMenuLabel = "Stream Player ";

    isoImage.efiSplashImage = ./splash-efi.png;
    isoImage.splashImage = ./splash-legacy.png;
    isoImage.storeContents = lib.mkForce [ config.system.build.toplevel ] ;

    isoImage.contents = [{
      source = pkgs.writeText "stream-target" cfg.defaultStream;
      target = "boot/stream.txt";
    }];

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
  };
}

