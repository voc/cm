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
    rev = "88f9328234b215590d51313ef8aa2f8d86df338e";
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
