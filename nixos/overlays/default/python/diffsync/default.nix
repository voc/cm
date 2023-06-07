{ lib, buildPythonPackage, fetchPypi, pydantic, structlog, colorama, redis, poetry }:

buildPythonPackage rec {
  pname = "diffsync";
  version = "1.8.0";
  format = "pyproject";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-HVnhEAnEalVQGu6HwxuXjavaE3rjIEkQVodnHF52dbk=";
  };

  propagatedBuildInputs = [ pydantic structlog colorama redis poetry ];

  pythonImportsCheck = [ "diffsync" ];
}
