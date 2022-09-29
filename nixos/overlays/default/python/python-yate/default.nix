{ lib, buildPythonPackage, fetchPypi, async-timeout }:

buildPythonPackage rec {
  pname = "python-yate";
  version = "0.3.1";

  src = fetchPypi {
    inherit pname version;
    sha256 = "5e806802dc47a35c855b60cd459a2c98fb0109c7fc099f3e9f83a1a38abf9f90";
  };

  propagatedBuildInputs = [ async-timeout ];

  pythonImportsCheck = [ "yate" ];
}
