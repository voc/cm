{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nixosTests,
  nix-update-script,
  ffmpeg,
}:

buildGoModule rec {
  pname = "srtrelay";
  version = "1.4.0";

  env.CGO_ENABLED = 0;
  doCheck = false; # skip tests

  src = fetchFromGitHub {
    owner = "voc";
    repo = "srtrelay";
    rev = "1e19ebf3b31f0196ccf7ceaa6f1c56551d4592c0";
    hash = "sha256-GqDucrG/nBmJK9SGZX1dWNoFm/9LVXfq6mBI9PWTQVQ=";
    #hash = lib.fakeHash;
  };

  vendorHash = "sha256-8zEyM9bZI3j5oOYjGhHmiQOmaXeEekDHVuqGwDULhGc=";
  #vendorHash = lib.fakeHash;

  nativeBuildInputs = [
    ffmpeg
  ];

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
