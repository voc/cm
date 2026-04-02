{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nixosTests,
  nix-update-script,
}:

buildGoModule rec {
  pname = "stream-api";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "voc";
    repo = "stream-api";
    rev = "85d2c9588791f0adb5b00cc111bbce92d4d2720b";
    hash = "sha256-yqEEdZm7wix4XbXbMIFP2+Z0EhNHhzKya/xHpdaf/uI=";
    #hash = lib.fakeHash;
  };

  vendorHash = "sha256-zs80HyLJ20VppqOCgyEZL7TvugV6Xbp6FdtE7m5pSpk=";
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
    maintainers = with lib.maintainers; [
      ischluff
    ];
    mainProgram = "stream-api";
  };
}