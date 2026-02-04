{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  fetchNpmDeps,
  unzip,
  nodejs_22,
  npmHooks,
  makeWrapper,
  python3,
  pkg-config,
  vips,
  jq,
  version ? "2.0.0-rc.4",
  hash ? "sha256-T7VuDoSKNkQYfaPkLY5q3C1sC3Yc1hXj2qEkKOOioVE=",
  npmDepsHash ? "sha256-yW9uzPALGdPrrUV129ToXayLyeLbAK9mCl2emCPYUdc=",
}:

let
  nodejs = nodejs_22;

  pythonEnv = python3.withPackages (ps: with ps; [
    apprise
  ]);
  
  plankaUnpacked = stdenvNoCC.mkDerivation {
    pname = "planka-unpacked";
    inherit version;
    
    src = fetchurl {
      url = "https://github.com/plankanban/planka/releases/download/v${version}/planka-prebuild.zip";
      inherit hash;
    };
    
    nativeBuildInputs = [ unzip jq ];
    
    unpackPhase = ''
      unzip $src
    '';
    
    installPhase = ''
      cp -r planka $out

      cd $out
      jq '.scripts.postinstall = "patch-package" | del(.scripts["setup-python"])' package.json > package.json.tmp
      mv package.json.tmp package.json
    '';
  };
in
stdenv.mkDerivation rec {
  pname = "planka";
  inherit version;

  src = plankaUnpacked;

  npmDeps = fetchNpmDeps {
    src = plankaUnpacked;
    hash = npmDepsHash;
  };

  nativeBuildInputs = [
    nodejs
    makeWrapper
    python3
    pkg-config
    npmHooks.npmConfigHook
  ];

  buildInputs = [
    vips
  ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/planka $out/bin
    cp -r . $out/lib/planka/

    mkdir -p $out/lib/planka/.venv/bin
    ln -s ${pythonEnv}/bin/python3 $out/lib/planka/.venv/bin/python3
    ln -s ${pythonEnv}/bin/python $out/lib/planka/.venv/bin/python
    for bin in apprise pip3 pip; do
      if [ -e "${pythonEnv}/bin/$bin" ]; then
        ln -s ${pythonEnv}/bin/$bin $out/lib/planka/.venv/bin/$bin
      fi
    done

    makeWrapper ${nodejs}/bin/node $out/bin/planka \
      --add-flags "$out/lib/planka/app.js" \
      --set NODE_ENV production \
      --prefix NODE_PATH : "$out/lib/planka/node_modules"

    cat > $out/bin/planka-db-init << EOF
#!/usr/bin/env bash
set -euo pipefail
cd $out/lib/planka
exec ${nodejs}/bin/npm run db:init "\$@"
EOF
    chmod +x $out/bin/planka-db-init

    cat > $out/bin/planka-db-seed << EOF
#!/usr/bin/env bash
set -euo pipefail
cd $out/lib/planka
exec ${nodejs}/bin/npm run db:seed "\$@"
EOF
    chmod +x $out/bin/planka-db-seed

    cat > $out/bin/planka-db-migrate << EOF
#!/usr/bin/env bash
set -euo pipefail
cd $out/lib/planka
exec ${nodejs}/bin/npm run db:migrate "\$@"
EOF
    chmod +x $out/bin/planka-db-migrate

    cat > $out/bin/planka-db-upgrade << EOF
#!/usr/bin/env bash
set -euo pipefail
cd $out/lib/planka
exec ${nodejs}/bin/npm run db:upgrade "\$@"
EOF
    chmod +x $out/bin/planka-db-upgrade

    runHook postInstall
  '';

  passthru.nodejs = nodejs;

  meta = with lib; {
    description = "Kanban board for project tracking";
    homepage = "https://planka.app";
    license = licenses.agpl3Only;
    platforms = platforms.linux;
    mainProgram = "planka";
  };
}
