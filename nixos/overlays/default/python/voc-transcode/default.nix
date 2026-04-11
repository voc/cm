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
    rev = "d3e0c36d364b7e1de799358c8cdfc4cfa56e3854";
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
