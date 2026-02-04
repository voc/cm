{ lib, stdenv }:

stdenv.mkDerivation {
  pname = "taiga-contrib-oidc-auth-frontend";
  version = "unstable-2024-01-15";

  src = ./dist;

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/plugins/oidc-auth
    cp -r * $out/plugins/oidc-auth/
    runHook postInstall
  '';

  meta = with lib; {
    description = "OIDC authentication frontend plugin for Taiga";
    homepage = "https://github.com/fabianmp/taiga-contrib-oidc-auth";
    license = licenses.agpl3Only;
  };
}