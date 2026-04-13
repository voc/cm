{
  description = "c3voc bundlewrap";

  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.11";
  inputs.nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils, ... } @ inputs: flake-utils.lib.eachSystem ([
    "x86_64-linux"
    "x86_64-darwin"
    "aarch64-linux"
    "aarch64-darwin"
  ]) (system:
    let
      pkgsUnstable = (import inputs.nixpkgs-unstable {inherit system;});
      pkgs = (import nixpkgs {
        inherit system;
        overlays = [(final: prev: {
          bundlewrap = pkgsUnstable.bundlewrap;
        })];
      });
    in {
      legacyPackages = pkgs;
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          curl
          rsync
          bundlewrap
          (python3.withPackages (py: [
            py.virtualenv
          ]))
        ];
      };
    });
}
