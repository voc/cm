{
  lib,
  buildGoModule,
  fetchFromGitea,
  nixosTests,
  nix-update-script,
}:

buildGoModule rec {
  pname = "stream-api";
  version = "0.2.1";

  src = fetchFromGitea {
    domain = "forgejo.c3voc.de";
    owner = "voc";
    repo = "stream-api";
    rev = "v${version}";
    hash = "sha256-1Zt1moRiK2yU9B1jXEW3iGQqb/DKV+csPeSWj2oCaKM=";
    #hash = lib.fakeHash; # Use after updating version
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
    maintainers = with lib.maintainers; [ ischluff ];
    mainProgram = "stream-api";
  };
}
