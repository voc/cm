# NixOS Host Configuration and Documentation

## General Information about NixOS

First you have to understand that Nix is and means multiple thing. There is:
- Nix the language
- Nix the package-manager
- NixOS the distribution
- Nix the german word "nichts"

There are some offical guides to NixOS that you can find on [nixos.org](https://nixos.org/learn.html), an other source of information is the unoffical user [wiki](https://nixos.wiki/) and for a general introduction you can look at [zero-to-nix](https://zero-to-nix.com/).  

### Nix language
Nix is a Functional programming language designed to be used to define packages and modules for the package-manger and the distro.
Because it's usally used as a special purpose language it also has some quite specific built-ins, like ```fetchFromGit``` which takes a few parameters like the url to clone from or the rev, which is the revison to checkout also known as commit hash. It is proably note worthy that it is turing complete and some people use it for other things then package defenitions or modules. For more details there is an entry in the [wiki](https://nixos.wiki/wiki/Overview_of_the_Nix_Language)

### Nix package-manger
The nix package-manager can be universaly used under any Linux-Distro and even MacOS. It install packages from package-definitions which represent a usally to most part reproducible declartion of what a package actaually is. This is achived by having a hash of the source in the package definition. But fear not you don't have to build everything from source there are chache servers. The most used chache server is probably [cachix](https://www.cachix.org/) 

### NixOS 
This is the distribution encorperating Nix in it's core. The configuration of a standard install can be found in ```/etc/nixos/configuration.nix``` and it defines basically any aspect of the system except for the formating of the disks (there are ways to do that if you really want that). A example option would be ```networking.hostname = foo;```. Those options are defined in so called modules, and a easy way to search through these options is the [web-based-search](https://search.nixos.org/options?). 

You probably want to just play around and look at stuff for you self. An easy way to do that would be to install a VM. You can also click one at hetzner or any other hosting provider, there are a few informations about that in the [wiki](https://nixos.wiki/wiki/NixOS_friendly_hosters). If you have a proxmox server or cluster running you can spin up an lxc container to play with nix, this is also documented in the [wiki](https://nixos.wiki/wiki/Proxmox_Virtual_Environment).
