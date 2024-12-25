{
  description = "c3voc bundlewrap";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils } @ inputs: flake-utils.lib.eachSystem ([
    "x86_64-linux"
    "x86_64-darwin"
    "aarch64-linux"
    "aarch64-darwin"
  ]) (system:
    let
      pkgs = (import nixpkgs { inherit system; });
    in {
      legacyPackages = pkgs;
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          curl
          rsync
          (python3.withPackages (py: [
            py.bundlewrap
            py.bundlewrap-keepass

            py.virtualenv
          ]))
        ];
      };
    });
}
