{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:

stdenvNoCC.mkDerivation rec {
  pname = "taiga-front-dist";
  version = "6.8.1";

  src = fetchFromGitHub {
    owner = "taigaio";
    repo = "taiga-front-dist";
    rev = "stable";
    hash = "sha256-oQHnYvTtfYDulNk6hEGMLIAbVkj9dZV8dUbB7miJtzo=";
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/taiga-front
    cp -r dist/* $out/share/taiga-front/

    rm -f $out/share/taiga-front/conf.json
    rm -f $out/share/taiga-front/conf.example.json

    runHook postInstall
  '';

  meta = with lib; {
    description = "Taiga frontend - Angular SPA for agile project management";
    homepage = "https://github.com/taigaio/taiga-front-dist";
    license = licenses.mpl20;
    platforms = platforms.all;
  };
}
