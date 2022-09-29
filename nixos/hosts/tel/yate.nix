{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    inputs.self.nixosModules.yate
    inputs.self.nixosModules.fieldpoc
  ];
  sops.secrets.ommpassword = {};
  sops.secrets.sipsecret = {};

  services.fieldpoc = {
    enable = true;
    ommIp = "omm.c3voc.de";
    ommUser = "omm";
    ommPasswordPath = config.sops.secrets.ommpassword.path;
    sipsecretPath = config.sops.secrets.sipsecret.path;
  };

  services.yate.config = {
    accfile.dialout = {
      enabled = "yes";
      protocol = "sip";
      username = "yate";
      password = "yate";
      registrar = "yate-dialup.bula22.de";
    };
    regexroute = "[default]
\${username}^$=-;error=noauth
^yate$=goto dialin
^.*$=line/\\0;line=dialout
[dialin]
\${sip_x-called}^.*$=lateroute/\\1";
    ysipchan = {
      general = {
        ignorevia = "yes";
      };
      #"listener general".enable = "no";
      #"listener dect" = {
      #  type = "udp";
      #  addr = "10.42.132.1";
      #  port = "5060";
      #};
      #"listener sip" = {
      #  type = "udp";
      #  addr = "10.42.133.1";
      #  port = "5060";
      #};
      #"listener voip" = {
      #  type = "udp";
      #  addr = "10.42.10.6";
      #  port = "5060";
      #  default = "yes";
      #};
    };
    ysnmpagent = {
      general.port = 161;
      snmp_v2.ro_community = "yate";
    };
  };

  networking.firewall.allowedUDPPorts = [ 161 ];

  environment.systemPackages = with pkgs; [
    (writers.makePythonWriter python310 python310.pkgs "/bin/dect_claim" { libraries = [ python310.pkgs.python-yate ]; } (builtins.readFile ./dect_claim.py))
    (runCommand "yintro.slin" {} ''
      mkdir -p $out/share/sounds/yate
      ln -s ${./yintro.slin} $out/share/sounds/yate/yintro.slin
    '')
  ];

  systemd.services.fieldpoc-nerd = {
    wantedBy = ["multi-user.target"];
    startAt = "*-*-* *:*:00";
    script = let
      reloadScript = pkgs.writeText "reload" ''
        spawn ${pkgs.inetutils}/bin/telnet localhost 9437
        expect "> "
        send "reload\n"
        expect "> "
        send "exit\n"
        expect "disconnecting"
      '';
    in ''
      ${pkgs.curl}/bin/curl https://nerd.bula22.de/export.json\?event=1 > /etc/fieldpoc/extensions.json
      ${pkgs.expect}/bin/expect ${reloadScript}
    '';
  };
}
