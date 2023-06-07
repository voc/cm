{ lib
, fetchFromGitHub
, python310
}:

python310.pkgs.buildPythonApplication rec {
  pname = "nerd";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "dect-e";
    repo = pname;
    #rev = "v${version}";
    rev = "819390a47426af1d617e011fd0576b4d87235ae6";
    sha256 = "sha256-WkJNNqiKTX/5zyvje5YeSoG0jz8nLpJOZaDdUoNrl7Y=";
  };

  sourceRoot = "source/src";

  format = "pyproject";

  buildInputs = [ python310 python310.pkgs.hatchling ];
  propagatedBuildInputs = with python310.pkgs; [
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
