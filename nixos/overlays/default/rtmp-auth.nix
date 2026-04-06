{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nixosTests,
  nix-update-script,
  statik,
  protobuf,
  protoc-gen-go,
}:

buildGoModule rec {
  pname = "rtmp-auth";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "voc";
    repo = "rtmp-auth";
    rev = "7422875299b4c988fb4550ad6b35175ef08f25ca";
    hash = "sha256-71PvNBKdvkNSqwCHWZZVAHPa1eEx1Ba3RZqmLy4CBn8=";
    #hash = lib.fakeHash;
  };

  vendorHash = "sha256-rZZMLZtCvXJmMKYr4rPLTaHqtV6QouKClZgRYlJM1sw=";
  #vendorHash = lib.fakeHash;

  nativeBuildInputs = [
    statik
    protobuf
    protoc-gen-go
  ];

  preBuild = ''
    statik -f -src=public/ -dest=.
    protoc -I=storage/ --go_opt=paths=source_relative --go_out=storage/ storage/storage.proto
  '';

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
