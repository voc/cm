{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
    ./base/users.nix
  ];
  boot.isContainer = true;

  systemd.suppressedSystemUnits = [
    "dev-mqueue.mount"
    "sys-kernel-debug.mount"
    "sys-fs-fuse-connections.mount"
  ];
  system.stateVersion = "25.11";
  nix.settings.trusted-users = [ "voc" "root" ];
  #users.users.voc =
  #  {
  #    isNormalUser = true;
  #    extraGroups = [ "wheel" ];
  #    hashedPassword = "$y$j9T$2VKYFKdwaPqJI8JJJueCB.$pmOqTko.X7roAS9zrnaDQpf481f8eFX5puArzPyNonA";
  #    openssh.authorizedKeys.keys = [
  #      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP3VMGqSKqxQYbCTc1QPwTc3m8eHPSMqwUgE4D1k9Z95 derchris@air.derchris.local"
  #      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOTClYJw4oZoJyVO8OUVbVeLA7nJPWwapEF5wNmguzG/ derchris@nixos"
  #    ];
  #  };
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
    settings.PermitRootLogin = "no";
    settings.pubkeyAuthentication = true;
  };
  security.sudo.wheelNeedsPassword = false;
}