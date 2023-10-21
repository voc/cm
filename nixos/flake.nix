{
  description = "c3voc nixOS config management";

  inputs.nixpkgs.url = "nixpkgs/nixos-23.05";
  inputs.deploy-rs = {
    url = "github:serokell/deploy-rs";
    inputs.nixpkgs.follows = "/nixpkgs";
  };
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "/nixpkgs";
  };
  inputs.home-manager = {
    url = "github:nix-community/home-manager/release-23.05";
    inputs.nixpkgs.follows = "/nixpkgs";
  };
  inputs.nixos-mailserver = {
    url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
    inputs.nixpkgs.follows = "/nixpkgs";
    inputs.utils.follows = "/flake-utils";
  };

  inputs.flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;
  };

  outputs = { self, nixpkgs, deploy-rs, flake-utils, sops-nix, home-manager, flake-compat, ... }@inputs: let
    hostsDir = "${../nixos}/hosts";
    hostNames = with nixpkgs.lib; attrNames
      (filterAttrs (name: type: type == "directory") (builtins.readDir hostsDir));
    hostConfig = host: if builtins.pathExists "${hostsDir}/${host}/meta.nix"
                        then (import "${hostsDir}/${host}/meta.nix")
                        else {
                          nixosConfiguration = nixpkgs.lib.nixosSystem {
                            system = "x86_64-linux";
                            modules = [
                              "${hostsDir}/${host}/configuration.nix"
                              ./profiles/base

                              self.nixosModules.nftables
                              sops-nix.nixosModules.sops
                              home-manager.nixosModules.home-manager
                              {
                                networking.hostName = host;
                                nixpkgs.overlays = [ self.overlays.default ];
                                sops.defaultSopsFile = "${hostsDir}/${host}/secrets.yaml";
                              }
                            ];
                            specialArgs.inputs = inputs;
                          };
                          deploy = {
                            hostname = "${host}.c3voc.de";
                            profiles.system = {
                              user = "root";
                              path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.${host};
                            };
                          };
                        };
    hosts = with nixpkgs.lib; listToAttrs (map (name: nameValuePair name (hostConfig name)) hostNames);
  in {
    nixosConfigurations = builtins.mapAttrs (host: config: config.nixosConfiguration) hosts;
    overlays = with nixpkgs.lib; mapAttrs (name: _: import ./overlays/${name})
      (filterAttrs (name: type: type == "directory") (builtins.readDir ./overlays));
    deploy.nodes = builtins.mapAttrs (host: config: config.deploy) hosts;

    nixosModules = {
      nftables = import ./modules/nftables;
      yate = import ./modules/yate;
      fieldpoc = import ./modules/fieldpoc;
    };
    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
  } // flake-utils.lib.eachSystem ([ "x86_64-linux" "x86_64-darwin" "aarch64-darwin"]) (system: let
    pkgs = (import nixpkgs { inherit system; });
  in {
    devShells.default = pkgs.mkShell {
      buildInputs = [
        deploy-rs.packages.${system}.deploy-rs
        sops-nix.packages.${system}.sops-init-gpg-key
        pkgs.age pkgs.sops
      ];
    };
  });
}
