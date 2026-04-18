{
  lib,
  fetchurl,
  perlPackages,
  NetMQTT
}:

# generated with nix-generate-from-cpan

with perlPackages;

buildPerlPackage {
  pname = "AnyEvent-MQTT";
  version = "1.212810";
  src = fetchurl {
    url = "mirror://cpan/authors/id/B/BE/BEANZ/AnyEvent-MQTT-1.212810.tar.gz";
    hash = "sha256-1TMjRteLoFV0TcwOj7g1UNquzNHPDXzZSynYpSkDyqU=";
  };
  #buildInputs = [ AnyEventMockTCPServer ];
  propagatedBuildInputs = [ AnyEvent NetMQTT SubName ];
  #runCheck = false;
  meta = {
    homepage = "http://search.cpan.org/dist/AnyEvent-MQTT/";
    description = "AnyEvent module for an MQTT client";
    license = with lib.licenses; [ artistic1 gpl1Plus ];
  };
}
