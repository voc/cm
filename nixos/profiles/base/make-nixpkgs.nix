{ pkgs, lib, config, ... }:

let
  nixpkgs = lib.cleanSource pkgs.path;

  nixSources = pkgs.runCommand "nixos-${config.system.nixos.version}" {
    preferLocalBuild = true;
  } ''
    mkdir -p $out
    cd ${nixpkgs.outPath}
    tar -cpf $out/nixpkgs.tar.gz .
    sha256sum $out/nixpkgs.tar.gz | cut -d " " -f 1 > $out/nixpkgs.sha256
    cp -prd ${nixpkgs.outPath} $out/nixpkgs
    chmod -R u+w $out/nixpkgs
    ${lib.optionalString (config.system.nixos.revision != null) ''
      echo -n ${config.system.nixos.revision} > $out/nixpkgs/.git-revision
    ''}
    echo -n ${config.system.nixos.versionSuffix} > $out/nixpkgs/.git-revision
    echo ${config.system.nixos.versionSuffix} | sed -e s/pre// > $out/nixpkgs/svn-revision
    date +%s > $out/last_updated
  '';
in {
  environment.etc."src".source = nixSources;
  environment.variables.NIX_PATH = lib.mkOverride 25 "/etc/src";
}
