{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/profiles/qemu-guest.nix")
    ];

  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  fileSystems."/" =
    { device = "rpool/local/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/5d7cfdc0-3155-4666-a580-0838b2ccdbcd";
      fsType = "ext2";
    };

  fileSystems."/nix" =
    { device = "rpool/local/nix";
      fsType = "zfs";
    };

  fileSystems."/persist" =
    { device = "tank/safe/persist";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "tank/safe/home";
      fsType = "zfs";
    };

  fileSystems."/var/log" =
    { device = "rpool/local/log";
      fsType = "zfs";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/aca22a24-13c6-45ff-8dac-8cf4f4d94eeb"; }
    ];


  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
