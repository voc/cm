{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nixosTests,
  nix-update-script,
}:

buildGoModule rec {
  pname = "rtmp-auth";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "voc";
    repo = "rtmp-auth";
    rev = "8508dd7a288d46636a7cf32e00ae6e47c2844603";
    #hash = "sha256-MYKz4QA8U4jflC9DofFntHS9yjzVUqpvAVqrgnuWb7w=";
    hash = lib.fakeHash;
  };

  #vendorHash = "sha256-zs80HyLJ20VppqOCgyEZL7TvugV6Xbp6FdtE7m5pSpk=";
  vendorHash = lib.fakeHash;

  meta = {
    description = "Stream api for cdn automation";
    homepage = "https://github.com/voc/rtmp-auth";
    platforms = lib.platforms.linux;
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      ischluff
    ];
    mainProgram = "rtmp-auth";
  };
}
