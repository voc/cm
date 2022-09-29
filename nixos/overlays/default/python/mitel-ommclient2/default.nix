{ lib, buildPythonPackage, hatchling, rsa }:

buildPythonPackage rec {
  pname = "mitel-ommclient2";
  version = "0.0.1";

  src = fetchGit {
    url = "https://git.clerie.de/clerie/mitel_ommclient2.git";
    ref = "main";
    rev = "f05ffdd86d7e0694fcea573e8ba246a59cd99bdc";
  };

  format = "pyproject";

  buildInputs = [ hatchling ];
  propagatedBuildInputs = [ rsa ];

  pythonImportsCheck = [ "mitel_ommclient2" ];
}
