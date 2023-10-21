{ config, lib, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "jira" ];
    ensureUsers = [{
      name = "jira";
      ensurePermissions = { "DATABASE jira" = "ALL PRIVILEGES"; };
    }];
  };

  services.jira = {
    enable = true;
    jrePackage = pkgs.jdk11;
    package = pkgs.atlassian-jira.overrideAttrs (prev: rec {
      version = "9.4.11";
      src = pkgs.fetchurl {
        url = "https://product-downloads.atlassian.com/software/jira/downloads/atlassian-jira-software-${version}.tar.gz";
        sha256 = "sha256-/4siWmEtBHuajlZNabrkODzKLxg7WlQUCzwk//gj0iE=";
      };
    });
    catalinaOptions = [
      "-Djava.awt.headless=true"
      "-Datlassian.standalone=JIRA"
      "-Dorg.apache.jasper.runtime.BodyContentImpl.LIMIT_BUFFER=true"
      "-Dmail.mime.decodeparameters=true"
      "-Dorg.dom4j.factory=true"
      "-Datlassian.plugins.enable.wait=300"
      "-Duser.timezone=Europe/Berlin"
      "-Datlassian.upm.server.data.disable=true"
      "-Djava.security.egd=file:/dev/./urandom"
      "-Dmail.mime.decodeparameters=true"
      "-XX:-OmitStackTraceInFastThrow"
      "-Xms8192m"
      "-Xmx8192m"
      # TODO: add jolokia
      # "-javaagent:/opt/jolokia-jvm-agent.jar=port=8051,agentContext=/jolokia,host=127.0.0.1"

      # java 11
      "-Djava.locale.providers=COMPAT"
      "-Xlog:gc*=debug:file=/var//log/jira/gc-`date +%F_%H-%M-%S`.log:tags,time,uptime,level:filecount=5,filesize=20M"

      # gc stuff
      "-XX:+ExplicitGCInvokesConcurrent"
      "-XX:+UseCodeCacheFlushing"
      "-XX:+UseG1GC"
      "-XX:ReservedCodeCacheSize=512m"
    ];

    home = "/persist/jira";
    proxy = {
      enable = true;
      name = "jira.c3voc.de";
    };
  };

  services.nginx.virtualHosts."jira.c3voc.de" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://localhost:${toString config.services.jira.listenPort}";
    };
  };

  services.postfix.enable = true;
  services.postfix.hostname = config.networking.fqdn;
  services.postfix.origin = config.networking.fqdn;
}
