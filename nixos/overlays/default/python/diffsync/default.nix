{ lib, buildPythonPackage, fetchPypi, pydantic, structlog, colorama, redis }:

buildPythonPackage rec {
  pname = "diffsync";
  version = "1.5.1";

  src = fetchPypi {
    inherit pname version;
    sha256 = "84a736d03d385bd07cf7c86f57385d4130c3c3273bf7bc90febe2fa530ee1aa6";
  };

  propagatedBuildInputs = [ pydantic structlog colorama redis ];

  pythonImportsCheck = [ "diffsync" ];
}
