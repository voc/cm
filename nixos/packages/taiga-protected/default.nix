{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  python3,
  makeWrapper,
}:

let
  pythonEnv = python3.withPackages (ps: with ps; [
    gunicorn
    python-dotenv
    werkzeug
  ]);
in
stdenvNoCC.mkDerivation rec {
  pname = "taiga-protected";
  version = "6.8.1";

  src = fetchFromGitHub {
    owner = "taigaio";
    repo = "taiga-protected";
    rev = "stable";
    hash = "sha256-XgLahzBJrEjSaNiSACzE6EhRWzNT8G56hmPoXEiF2RU=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/taiga-protected
    cp -r . $out/share/taiga-protected/

    mkdir -p $out/bin

    makeWrapper ${pythonEnv}/bin/gunicorn $out/bin/taiga-protected-gunicorn \
      --chdir "$out/share/taiga-protected" \
      --set PYTHONPATH "$out/share/taiga-protected"

    runHook postInstall
  '';

  passthru = {
    inherit pythonEnv;
  };

  meta = with lib; {
    description = "Taiga protected - token-validated attachment serving";
    homepage = "https://github.com/taigaio/taiga-protected";
    license = licenses.mpl20;
    platforms = platforms.linux;
  };
}
