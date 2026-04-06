{
  lib,
  buildPythonPackage,
  hatchling,
  pyyaml,
  consul,
  pystemd,
  paho-mqtt,
  requests,
  six,
}:

buildPythonPackage rec {
  pname = "voc-transcode";
  version = "1.0.0";

  src = fetchGit {
    url = "https://forgejo.c3voc.de/voc/transcode.git";
    ref = "feature/package";
    rev = "f7939503d8e18d4ac4d9000e15e9c0ee22f45725";
  };

  format = "pyproject";

  buildInputs = [ hatchling ];
  propagatedBuildInputs = [
    pyyaml
    consul
    pystemd
    paho-mqtt
    requests
    six
  ];
}
