{ lib
, python312
, fetchFromGitHub
}:

python312.pkgs.buildPythonPackage rec {
  pname = "taiga-contrib-oidc-auth";
  version = "unstable-2024-01-15";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "fabianmp";
    repo = "taiga-contrib-oidc-auth";
    rev = "6.8.1+fabianmp.0.1.0";
    hash = "sha256-N1N7L3EjahKETbWlEt3mLLDJSzp38yWyaZmB4S5A73k=";
  };

  sourceRoot = "${src.name}/back";

  nativeBuildInputs = [
    python312.pkgs.versiontools
  ];

  build-system = [ python312.pkgs.setuptools ];

  preBuild = ''
    substituteInPlace setup.py \
      --replace "setup_requires=['versiontools >= 1.9']," "" \
      --replace "setup_requires=['versiontools>=1.9']," "" \
      --replace "setup_requires=[\"versiontools >= 1.9\"]," "" \
      --replace "setup_requires=[\"versiontools>=1.9\"]," ""
  '';

  dependencies = [ ];

  dontCheckRuntimeDeps = true;

  doCheck = false;

  meta = with lib; {
    description = "OIDC authentication backend plugin for Taiga";
    homepage = "https://github.com/fabianmp/taiga-contrib-oidc-auth";
    license = licenses.agpl3Only;
  };
}