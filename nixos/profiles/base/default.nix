{ config, lib, name, pkgs, ... }:

{
  imports = [
    ./users.nix

    ../stream-player
  ];

  nix.settings = {
    trusted-users = [ "root" "@wheel" ];
  };

  # boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages;
  boot.kernelParams = [ "quiet" ];

  networking.hostName = lib.mkDefault name;
  networking.nftables.enable = lib.mkDefault true;
  networking.domain = lib.mkDefault "c3voc.de";

  services.journald.extraConfig = ''
    SystemMaxUse=512M
    MaxRetentionSec=48h
  '';
  nix.gc.automatic = lib.mkDefault true;
  nix.gc.options = lib.mkDefault "--delete-older-than 7d";
  environment.variables.EDITOR = "vim";

  home-manager.useGlobalPkgs = true;
  programs.command-not-found.enable = false;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = lib.mkDefault "no";
      GatewayPorts = lib.mkDefault "yes";
    };
    extraConfig = "StreamLocalBindUnlink yes";
  };
  programs.mosh.enable = true;
  security.sudo.wheelNeedsPassword = lib.mkDefault false;

  i18n.defaultLocale = "en_IE.UTF-8";
  time.timeZone = "UTC";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "de";
  };

  programs.mtr.enable = true;

  environment.systemPackages = with pkgs; [
    kitty.terminfo
    htop
    tcpdump
    nload
    iftop
    bottom
    lm_sensors
    iperf
    usbutils
    pciutils
    binutils
    dnsutils
    cryptsetup
    gptfdisk

    ripgrep
    fd
    pv
    progress
    parallel
    file
    vim
    git
    rsync
    whois
    p7zip
    zstd
    gnupg
    pinentry-curses
  ];

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  system.autoUpgrade = {
    enable = true;
    allowReboot = lib.mkDefault false;
    dates = "03:30";
    flake = "github:voc/cm?dir=nixos";
    rebootWindow.lower = "03:00";
    rebootWindow.upper = "05:00";
  };

  programs.fuse.userAllowOther = true;
}
