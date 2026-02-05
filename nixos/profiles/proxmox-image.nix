{ config, lib, name, ... }:

{
  config = {
    proxmox.qemuConf = {
      name = "nixos-${name}-${config.system.nixos.label}";
      net0 = "virtio=00:00:00:00:00:00,bridge=vmbr2,firewall=0";
      virtio0 = "local-zfs:vm-9999-disk-0";
      agent = true;
    };
    virtualisation.diskSize = "32G";

    boot = {
      kernelParams = [ "console=tty0" "console=ttyS0" ];
      loader.timeout = lib.mkForce 1;
    };

    services.cloud-init = {
      enable = true;
      network.enable = true;
    };

    system.stateVersion = "25.11";
  };
}
