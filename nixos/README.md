# NixOS Host Configuration and Documentation

## General Information about NixOS

First you have to understand that Nix is and means multiple thing. There is:
- Nix the language
- Nix the package-manager
- NixOS the distribution
- Nix the german word "nichts"

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

To deploy a specific host simple run

    colmena apply switch --on "<name from host.nix>"

When you are on a non `x86_64-linux` platform you want to use a nix remote builder.
In case you don't have a remote-builder available you can do `--build-on-target` to use the target machine as builder.


### Add new host to this repo

Install `nixos` on a host, copy `configuration.nix` and `hardware-configuration.nix` to the host folder in this repo.
Rename `configuration.nix` to `default.nix`. ... profit!

Maybe there will be a better way for this is the future, mainly for the `nixos` install part, which is kind of annoying.

