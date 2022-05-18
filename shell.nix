{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # keep this line if you use bash
    bashInteractive

    (python3.withPackages (py: [ py.ansible py.pykeepass ]))
    ansible
  ];
}
