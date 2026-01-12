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
    rev = "e8f69213f20e8a29dda91cafce88c70a7efcd7c4";
    hash = "sha256-GWptodKp7WqWn3nX87Ezp3h8SA501IGZuDB+DLOHkqQ=";
  };

  vendorHash = "sha256-H6x15uNm5+fT5lXp5iXdmLGrGsv09UGrG8VA2wWrftQ=";

  # we don't build monitor ui right now
  preBuild = ''
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