{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  buildNpmPackage,
  nodejs_22,
}:

buildNpmPackage rec {
  pname = "taiga-events";
  version = "6.8.1";

  src = fetchFromGitHub {
    owner = "taigaio";
    repo = "taiga-events";
    rev = "stable";
    hash = "sha256-uX1s/opTJLtkNw2tbPtal1Lh/autQHp0cOywRSBFLoQ=";
  };

  nodejs = nodejs_22;

  npmDepsHash = "sha256-L+D0gbdBAtGx8VtMomDNJp9zWpAZbLwajUfSTRJLiCU=";

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/taiga-events
    cp -r . $out/lib/taiga-events/
    cp -r node_modules $out/lib/taiga-events/

    mkdir -p $out/bin
    cat > $out/bin/taiga-events <<EOF
    #!/usr/bin/env bash
    exec ${nodejs}/bin/node $out/lib/taiga-events/src/index.js "\$@"
    EOF
    chmod +x $out/bin/taiga-events

    runHook postInstall
  '';

  meta = with lib; {
    description = "Taiga events - WebSocket server for real-time updates";
    homepage = "https://github.com/taigaio/taiga-events";
    license = licenses.mpl20;
    platforms = platforms.linux;
  };
}
