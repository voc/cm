{ lib
, buildPythonApplication
, makePythonPath
, fetchFromGitHub
, python310
, hatchling
, django_4
, django-bootstrap5
, django-admin-autocomplete-filter
, django-verify-email
}:

buildPythonApplication rec {
  pname = "nerd";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "dect-e";
    repo = pname;
    #rev = "v${version}";
    rev = "83a0c73c5232f9bfa63c2898a958d67a2a17caeb";
    sha256 = "sha256-7ItooKr2pUMqkpGLJ2NP5vlAs/xRH/Q1n5kTgbTDgWs=";
  };

  sourceRoot = "source/src";

  format = "pyproject";

  buildInputs = [ python310 hatchling ];
  propagatedBuildInputs = [
    django_4
    django-bootstrap5
    django-admin-autocomplete-filter
    django-verify-email
  ];

  postInstall = ''
    python ./manage.py collectstatic

    mkdir -p $out/var/lib/nerd
    cp -r static $out/var/lib/nerd/
  '';

  passthru = {
    # PYTHONPATH of all dependencies used by the package
    pythonPath = python310.pkgs.makePythonPath propagatedBuildInputs;
  };

  doCheck = false;
}
