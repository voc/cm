{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nixosTests,
  nix-update-script,
}:

buildGoModule rec {
  pname = "srtrelay";
  version = "1.4.0";

  src = fetchFromGitHub {
    owner = "voc";
    repo = "srtrelay";
    rev = "8508dd7a288d46636a7cf32e00ae6e47c2844603";
    #hash = "sha256-MYKz4QA8U4jflC9DofFntHS9yjzVUqpvAVqrgnuWb7w=";
    hash = lib.fakeHash;
  };

  #vendorHash = "sha256-zs80HyLJ20VppqOCgyEZL7TvugV6Xbp6FdtE7m5pSpk=";
  vendorHash = lib.fakeHash;

  meta = {
    description = "SRT relay server for distributing media streams to multiple clients";
    homepage = "https://github.com/voc/srtrelay";
    platforms = lib.platforms.linux;
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      ischluff
    ];
    mainProgram = "srtrelay";
  };
}
