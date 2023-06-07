{ lib
, python310
, ywsd
}:

with python310.pkgs; buildPythonApplication rec {
  pname = "fieldpoc";
  version = "0.11.0";

  src = fetchGit {
    url = "https://git.n0emis.eu/n0emis/fieldpoc.git";
    ref = "main";
    rev = "2f1347f3415249cb116501af1f5e3282afca24be";
  };

  format = "pyproject";

  buildInputs = [ hatchling ];
  propagatedBuildInputs = [ mitel-ommclient2 sqlalchemy ywsd diffsync ];
}
