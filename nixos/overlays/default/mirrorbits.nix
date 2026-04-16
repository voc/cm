{
  lib,
  versionCheckHook,
  buildGoModule,
  fetchFromGitHub,
  nixosTests,
  nix-update-script,
  pkg-config,
  zlib,
  geoip,
}:

buildGoModule (finalAttrs: {
  pname = "mirrorbits-voc";
  version = "0.6.1";

  src = fetchFromGitHub {
    owner = "videolabs";
    repo = "mirrorbits";
    rev = "7357f8cfe8d701b8f53996539b5a27fd4af584e9";
    hash = "sha256-Jl8lki4DcA1pkK24DP9aobEJaBBx82zOJ92yuhFAKMw=";
    #hash = lib.fakeHash;
  };

  vendorHash = "sha256-cdD9RvOtgN/SHtgrtrucnUI+nnO/FabUyPRdvgoL44o=";
  #vendorHash = lib.fakeHash;

  subPackages = [ "." ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/etix/mirrorbits/core.VERSION=${finalAttrs.version}"
  ];

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "version";

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    zlib
    geoip
  ];

  # redact some private information from mirror infos and remove stale vendor directory
  postPatch = ''
    sed -i -r 's/^(\s+(RsyncURL|AdminName|AdminEmail)\s+string\s+`[^`]+)`$/\1 json:"-"`/g' mirrors/mirrors.go
    rm -rf vendor
  '';

  postInstall = ''
    mkdir -p $out/share/templates
    cp -r templates/* $out/share/templates/
  '';

  meta = {
    description = "Mirrorbits is a geographical download redirector written in Go for distributing files efficiently across a set of mirrors. This version contains c3voc specific patches.";
    homepage = "https://github.com/videolabs/mirrorbits";
    platforms = lib.platforms.linux;
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      lukas2511
    ];
    mainProgram = "mirrorbits";
  };
})
