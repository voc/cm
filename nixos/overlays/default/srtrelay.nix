{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nixosTests,
  nix-update-script,
  srt,
  ffmpeg,
}:

buildGoModule rec {
  pname = "srtrelay";
  version = "1.4.0";

  src = fetchFromGitHub {
    owner = "voc";
    repo = "srtrelay";
    rev = "ba6bcfb023fc75b30ffab084a88841e1bd8e32b2";
    hash = "sha256-JjASUeKIrOlCcpd7cxU4DMA7ghmtWmJtb8EXxUtDYwI=";
    #hash = lib.fakeHash;
  };

  vendorHash = "sha256-72WkgeSQNTHQbfcYkFbHBON6yzSr8/VgHzE8FRaMcm8=";
  #vendorHash = lib.fakeHash;

  buildInputs = [
    srt
  ];

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
