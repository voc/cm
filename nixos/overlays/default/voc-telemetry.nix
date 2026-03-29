{
  lib,
  buildGoModule,
  fetchFromGitea,
}:

let 
    version = "0.0.4";
in
buildGoModule {
  pname = "voc-telemetry";
  version = version;
  src = fetchFromGitea {
    domain = "forgejo.c3voc.de";
    owner = "voc";
    repo = "voc-telemetry";
    rev = "v${version}";
    hash = "sha256-0Zo/sA8gY3Mf5fDXLk0rSPbYSj1hDNvbQ01VklMcn4o=";
    #hash = lib.fakeHash; # Use after updating version
  };
  tags = [ ];

  vendorHash = "sha256-/cxpaZRQy77T5iilEaXsgXji1MMdk8503OpYvPmrVZc=";

  meta = {
    description = "Server for collecting stream event telemetry";
    homepage = "https://forgejo.c3voc.de/voc/voc-telemetry";
    platforms = lib.platforms.linux;
  };
}