{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nixosTests,
  nix-update-script,
}:

buildGoModule rec {
  pname = "mirrorbits-serverlist-api";
  version = "0.0.0";

  src = fetchFromGitHub {
    owner = "manno";
    repo = "mirrorbits-serverlist-api";
    rev = "ae5343cc0bf2f69247b5b2addcf5f1340c180cda";
    hash = "sha256-0wZSTJ96i9RsHaG2E2sD2SNN/QNpNZYFnokAqlr3Rjc=";
    #hash = lib.fakeHash;
  };

  vendorHash = "sha256-BAlHG653pSEQbx1nuom0o0+li1E1p4gU484SCaU7SwU=";
  #vendorHash = lib.fakeHash;
  
  postPatch = ''
    sed -i 's/NewPool(":6379")/NewPool("[::1]:6379")/' main.go
  '';

  meta = {
    description = "Mirrorbits serverlist api";
    homepage = "https://github.com/manno/mirrorbits-serverlist-api";
    platforms = lib.platforms.linux;
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      lukas2511
    ];
    mainProgram = "mirrorbits";
  };
}
