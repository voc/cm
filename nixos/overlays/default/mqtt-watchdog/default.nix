{
  stdenv,
  makeWrapper,
  perl,
  perlPackages,
  AnyEventMQTT
}:

stdenv.mkDerivation {
  name = "mqtt-watchdog";

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = with perlPackages; [
    perl
    JSON
    AnyEvent
    AnyEventMQTT
    TextGlob
  ];

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    install -m 0755 ${./monitor.pl} $out/bin/mqtt-watchdog
    patchShebangs $out/bin/mqtt-watchdog
    wrapProgram $out/bin/mqtt-watchdog --set PERL5LIB $PERL5LIB
  '';
}
