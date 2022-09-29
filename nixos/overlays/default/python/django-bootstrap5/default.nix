{ lib
, buildPythonPackage
, fetchPypi
, django
, beautifulsoup4
}:

buildPythonPackage rec {
  pname = "django-bootstrap5";
  version = "21.3";

  src = fetchPypi {
    inherit pname version;
    sha256 = "35086341881780a44b2e27255894f6029fc5ef75e5a0ec8ebd82f47a5184fa73";
  };

  buildInputs = [
    django
  ];

  propagatedBuildInputs = [
    beautifulsoup4
  ];

  pythonImportsCheck = [ "django_bootstrap5" ];

  doCheck = false;
}
