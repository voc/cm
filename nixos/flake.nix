{
  description = "c3voc nixOS config management";

  inputs.nixpkgs.url = "nixpkgs/nixos-23.11";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "/nixpkgs";
  };
  inputs.home-manager = {
    url = "github:nix-community/home-manager/release-23.11";
    inputs.nixpkgs.follows = "/nixpkgs";
  };
  inputs.nixos-mailserver = {
    url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-23.11";
    inputs.nixpkgs.follows = "/nixpkgs";
    inputs.utils.follows = "/flake-utils";
  };
  inputs.authentik-nix = {
    url = "github:nix-community/authentik-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.nixos-generators = {
    url = "github:nix-community/nixos-generators";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;
  };

  outputs = { self, nixpkgs, flake-utils, sops-nix, home-manager, flake-compat, ... }@inputs: (
    let
      pkgs' = system: import nixpkgs {
        inherit system;
        overlays = with nixpkgs.lib; mapAttrsToList (name: _: import ./overlays/${name}) (
          filterAttrs (name: type: type == "directory") (builtins.readDir ./overlays)
        );
      };
    in (
    {
      colmena = {
        meta = {
          nixpkgs = pkgs' "x86_64-linux";
          specialArgs = { inherit inputs; };
        };

        defaults = { lib, name, ... }: {
          imports = [
            (./hosts + "/${name}")

            ./modules/fieldpoc
            ./modules/nftables
            ./modules/yate

            ./profiles/base

            sops-nix.nixosModules.sops
            home-manager.nixosModules.home-manager
          ];

          deployment = {
            targetHost = "${name}.c3voc.de";
            targetUser = lib.mkDefault null;
          };
          networking.hostName = name;
          sops.defaultSopsFile = ./hosts + "/${name}/secrets.yaml";
        };
      } // import ./hosts.nix;
      proxmoxImages = {
        base = inputs.nixos-generators.nixosGenerate {
          pkgs = pkgs' "x86_64-linux";
          format = "proxmox";
          modules = [
            ./profiles/proxmox-image.nix
            ./profiles/base
            home-manager.nixosModules.home-manager
          ];
          specialArgs = {
            name = "base";
          };
        };
      };
    } //  flake-utils.lib.eachSystem ([ "x86_64-linux" "x86_64-darwin" "aarch64-darwin"]) (system: let
      pkgs = pkgs' system;
    in {
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          age
          colmena
          sops

          sops-nix.packages.${system}.sops-init-gpg-key
        ];
      };
    }))
  );
}
