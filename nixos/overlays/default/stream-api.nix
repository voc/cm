{
  lib,
  buildGoModule,
  fetchFromGitea,
  nixosTests,
  nix-update-script,
}:

buildGoModule rec {
  pname = "stream-api";
  version = "0.2.3";

  src = fetchFromGitea {
    domain = "forgejo.c3voc.de";
    owner = "voc";
    repo = "stream-api";
    rev = "v${version}";
    hash = "sha256-DNmkY0MG8keanPUj2AvJqcUOBJv4Bs01d3dq1q/bmFc=";
    #hash = lib.fakeHash; # Use after updating version
  };

  vendorHash = "sha256-dhlFZrw3R6euEpSuZ2CbdyxAfCAppj1c0tkAPu3907U=";
  #vendorHash = lib.fakeHash;

  # we don't build monitor ui right now
  preBuild = ''
    mkdir -p monitor/frontend/public
    touch monitor/frontend/public/hello
  '';

  meta = {
    description = "Stream api for cdn automation";
    homepage = "https://github.com/voc/stream-api";
    platforms = lib.platforms.linux;
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ischluff ];
    mainProgram = "stream-api";
  };
}
