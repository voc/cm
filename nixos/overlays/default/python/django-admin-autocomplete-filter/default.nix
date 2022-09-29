{ lib
, buildPythonPackage
, fetchPypi
, django
}:

buildPythonPackage rec {
  pname = "django-admin-autocomplete-filter";
  version = "0.7.1";

  src = fetchPypi {
    inherit pname version;
    sha256 = "5a8c9a7016e03104627b80b40811dcc567f26759971e4407f933951546367ba0";
  };

  buildInputs = [
    django
  ];

  pythonImportsCheck = [ "admin_auto_filters" ];

  doCheck = false;
}
