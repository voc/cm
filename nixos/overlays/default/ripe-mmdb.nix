{ stdenv, fetchurl }:

stdenv.mkDerivation {
  name = "ripe-mmdb";
  version = "1.0.0";

  src = fetchurl {
    url = "https://forgejo.c3voc.de/api/packages/voc/generic/asn-mmdb/2026-03-29/ripe.mmdb";
    sha256 = "sha256-1U6a8OtleBQFz1Ca2efgUylpTOKlXtSbVmLSmZeHExE=";
  };
  dontUnpack = true;

  buildPhase = ''
    mkdir -p $out
    cp $src $out/db.mmdb
  '';

  installPhase = ''
    # The build phase already places files in $out
  '';

  meta = {
    description = "RIPE ASN DB in MaxMind format, generated using voc-telemetry tool";
    homepage = "https://forgejo.c3voc.de/voc/voc-telemetry";
  };
}
