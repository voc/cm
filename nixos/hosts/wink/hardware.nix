{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/profiles/qemu-guest.nix")
    ];

  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  fileSystems."/" = lib.mkForce
    { device = "/dev/disk/by-uuid/20492dcd-e992-4fc7-bed5-fee5baf487e1";
      fsType = "btrfs";
      options = [ "subvol=@" ];
    };

  fileSystems."/boot" = lib.mkForce
    { device = "/dev/disk/by-uuid/e7f5e3d7-a79b-4395-8df3-a6fb1fb13a88";
      fsType = "ext4";
    };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
