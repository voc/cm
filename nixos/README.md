# NixOS Host Configuration and Documentation

## General Information about NixOS

First you have to understand that Nix is and means multiple things – there is:
- `Nix` the language
- `Nix` the package-manager
- `NixOS` the distribution
- `Nix` the German slang word "nichts"

There are some offical guides to NixOS that you can find on [nixos.org](https://nixos.org/learn.html), an other source of information is the unoffical user [wiki](https://nixos.wiki/) and for a general introduction you can look at [zero-to-nix](https://zero-to-nix.com/).

## About this (part of the) repo

To use this repo and deploy hosts you need to have the nix packet manager installed on your local system.

Rough sturcture:
  * 'hosts/': host specific configuration, this are also the "starting point" for each host configuration
  * 'profiles/': profiles are commonly a set of configurations shared by multiple hosts
    * 'base/': base profile which is deployed to every host (as defined in `flake.nix`)
  * 'modules/': configuration modules, that provide options to configure single packages
  * 'flake.nix': starting point of the whole nix configuration
  * 'hosts.nix': hosts that can be deployed with this repo, maybe special deployment settings for the hosts

For each host deployed with this repo there is a set of default options configured for each host (`flake.nix` `outputs.colmena.default`) and all host specific options which should be placed under `hosts/<hostname>/`.

We use `colemena` to deploy configs to our `nix`-based hosts.

## Frequent tasks

### Deploy a host

To get a shell with colmena installed run in this directory:

    nix develop

To deploy a specific host simply run

    colmena apply switch --on "<name from host.nix>"

When you are on a non `x86_64-linux` platform you want to use a nix remote builder.
In case you don't have a remote-builder available you can do `--build-on-target` to use the target machine as builder.


### Set up a new Proxmox VM

For installation on proxmox generate a cloud-init capable VMA for import.

```
nix run github:nix-community/nixos-generators \
    --extra-experimental-features nix-command \
    --extra-experimental-features flakes \
    -- \
    --format proxmox \
    -I nixpkgs=channel:nixos-25.11
```

The command will return the path to a `.vma.zst` file. Copy this file to the desired proxmox host, and import it, e.g. like following:

```
# read carefully and change parameters where necessary
nextid=$(pvesh get /cluster/options --output-format json | jq '."next-id".lower | tonumber')
qmrestore \
    vzdump-qemu-nixos-25.11.8801.36a601196c4e.vma.zst \
    $nextid \
    --unique \
    --storage local-zfs
qm set $nextid \
    --name X.alb.c3voc.de \
    --cores 4 \
    --memory 4096 \
    --ciuser voc \
    --cipassword voc \
    --ipconfig0 ip=185.106.84.X/26,gw=185.106.84.1,ip6=2001:67c:20a0:e::X/64,gw6=2001:67c:20a0:e::1 \
    --net0 virtio,bridge=vmbr0,firewall=0,tag=67 \
    --sshkeys /home/voc/.ssh/authorized_keys
qm resize $nextid virtio0 16G # disk will be automatically grown inside of VM
qm cloudinit update $nextid
qm start $nextid
qm terminal $nextid # use Ctrl+O to exit
```

Now create a new host directory, and add a `default.nix`. Change stateVersion/hostName/domain as needed.

```
mkdir hosts/X
cat > hosts/X/default.nix << EOF
{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:

with lib;

let
in
{
  imports = [
    "\${modulesPath}/virtualisation/proxmox-image.nix"
    ../../profiles/server
  ];

  config = {
    system.stateVersion = "25.11"; # use version from image name and do not modify (even after updates)
    deployment.tags = [ ];

    networking.hostName = lib.mkOverride 1 "X";
    networking.domain = "alb.c3voc.de";
  };
}
EOF
```

Add the new host to hosts.nix and to .sops.yaml. You might want to use ssh-to-age to generate a key:

```
# ssh-keyscan 185.106.84.36 | ssh-to-age
age1nlnj3ny7rzc3xfp6n7fyjjypg9dm7lv9pt0t4hefcsh7gz9ejejsrafj2k
```

The command will print a warning about the ssh-rsa key type, just ignore that.

After adding the new host everywhere make sure to re-encrypt the sops secrets as documented below, commit your changes and deploy using colmena as described above.

### Add new (non-proxmox-vm) host to this repo

Install `nixos` on a host, copy `configuration.nix` and `hardware-configuration.nix` to the host folder in this repo.
Rename `configuration.nix` to `default.nix`. ... profit!

Maybe there will be a better way for this is the future, mainly for the `nixos` install part, which is kind of annoying.

### Reencrypt sops secrets
This is necessary after changing the sops key permissions. E.g. when adding a new public key.

This one-liner will find and try to update all secrets.
```
find . -type f -name '*.yaml' -exec sops updatekeys -y {} \;
```

## Specials

### Loudness Player

In the current working state the streams and i3layout are defined in `hosts/loudness-player/loudness-player.nix`. The loudness player machine does not have a fixed IP address or records in public DNS, so in order to deploy to this machine with `colmena` you need be on a network where the loudness player is reachable (e.g. same LAN segment) and then set up your SSH config to resolve `loudness-player.lan.c3voc.de` to the current IP address of the machine. 

	Host loudness-player.lan.c3voc.de
	Hostname 192.0.2.23

The machine's current IP address is shown in the i3 status bar when connected to a display.
