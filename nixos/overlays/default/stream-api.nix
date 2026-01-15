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
    rev = "6f7f8a4db0e5953716fc0b0c61ea3c4e47e241c1";
    hash = "sha256-TLoPph/kjZ8cuMse21krYKgeotY5pU8eSeXJYxO1byI=";
  };

  vendorHash = "sha256-H6x15uNm5+fT5lXp5iXdmLGrGsv09UGrG8VA2wWrftQ=";

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