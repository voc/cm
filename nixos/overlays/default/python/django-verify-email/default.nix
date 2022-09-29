{ lib
, buildPythonPackage
, fetchPypi
, django
}:

buildPythonPackage rec {
  pname = "Django-Verify-Email";
  version = "1.0.9";

  src = fetchPypi {
    inherit pname version;
    sha256 = "05d296a6a7ef03db07327b076093373e086d9e76e7fa9970a033e4e01168197f";
  };

  buildInputs = [
    django
  ];

  doCheck = false;
}
