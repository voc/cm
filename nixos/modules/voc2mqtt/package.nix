{
  lib,
  stdenv,
  makeWrapper,
  systemd,
  jq,
  iproute2,
  coreutils,
  gawk,
  gnused,
  bc,
  util-linux
}:

let
  scripts = [
    "voc2alert"
    "alert_shutdown.sh"
    "check_system.sh"
  ];

  # XXX hardcoded plugins to be deployed on all machines. in the
  # future this could be turned into nixos options which can then be
  # set from the machine config.
  plugins = [
    "disk_space.sh"
    "kernel_log.sh"
    "kernel_throttling.sh"
    "load.sh"
    "systemd_failed_units.sh"
  ];
in

stdenv.mkDerivation {
  name = "voc2mqtt-tools";
  src = ../../../common/mqtt-monitoring;

  nativeBuildInputs = [ makeWrapper ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/lib/plugins

    ${lib.concatMapStringsSep "\n" (s:
      "install -m 0755 $src/${s} $out/bin/${s}"
    ) scripts}

    ${lib.concatMapStringsSep "\n" (p:
      "install -m 0755 $src/plugins/${p} $out/lib/plugins/${p}"
    ) plugins}

    # only use minutely plugins for now
    substituteInPlace $out/bin/check_system.sh --replace-fail \
        "/usr/local/sbin/check_system.d" "$out/lib/plugins"
  '';

  postFixup = ''
    ${lib.concatMapStringsSep "\n" (s:
      "wrapProgram $out/bin/${s} --prefix PATH : " +
      lib.makeBinPath [ systemd jq iproute2 coreutils gawk gnused bc util-linux ]
    ) scripts}
  '';
}
