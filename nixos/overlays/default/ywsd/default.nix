{ lib
, python310
, fetchFromGitHub
}:

with python310.pkgs; buildPythonApplication rec {
  pname = "ywsd";
  version = "0.11.0";

  src = fetchFromGitHub {
    owner = "eventphone";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-9DloJSKR3Ck4Bsc0ICcAAD6LHIMeOHTe2rCx6nPINT4=";
  };

  patches = [ ./count.patch ];

  propagatedBuildInputs = [ aiopg aiohttp python-yate pyyaml sqlalchemy ];

  doCheck = false;
}
