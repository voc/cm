{
  lib,
  fetchurl,
  perlPackages,
}:

# generated with nix-generate-from-cpan

with perlPackages;

buildPerlPackage {
  pname = "Net-MQTT";
  version = "1.163170";
  src = fetchurl {
    url = "mirror://cpan/authors/id/B/BE/BEANZ/Net-MQTT-1.163170.tar.gz";
    hash = "sha256-661WubKLD6Z7KYM4L8GDijYbZj5gTPT5gs0vw2xLA5w=";
  };
  propagatedBuildInputs = [ ModulePluggable ];
  meta = {
    homepage = "http://search.cpan.org/dist/Net-MQTT/";
    description = "Perl modules for MQTT Protocol (http://mqtt.org/)";
    license = with lib.licenses; [
      artistic1
      gpl1Plus
    ];
  };
}
