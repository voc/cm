{ pkgs, ... }:

{
  config.services.dokuwiki.sites."wiki.lan.c3voc.de".templates = [
    (pkgs.stdenv.mkDerivation rec {
      name = "bootstrap3";
      version = "2024-02-06";
      src = pkgs.fetchFromGitHub {
        owner = "giterlizzi";
        repo = "dokuwiki-template-bootstrap3";
        rev = "v${version}";
        hash = "sha256-PSA/rHMkM/kMvOV7CP1byL8Ym4Qu7a4Rz+/aPX31x9k=";
      };
      installPhase = ''
        mkdir -p $out
        cp --recursive * $out/
      '';
    })
  ];
}
