args@{
  lib,
  pkgs,
  config,
  ...
}:

let
  fqdn = config.networking.hostName + "." + config.networking.domain;
  alertSource = ''grafana/explore?orgId=1&left=["now-1h","now","VictoriaMetrics",{"expr":{{$expr|jsonEscape|queryEscape}}},{"mode":"Metrics"},{"ui":[true,true,true,"none"]}]'';
in
{
  services.prometheus.alertmanager = {
    enable = true;
    listenAddress = "127.0.0.1";
    webExternalUrl = "https://${fqdn}/alertmanager";
    configuration = {
      global = {
        resolve_timeout = "5m";
      };
      route = {
        group_by = [
          "host"
          "alertname"
        ];
        repeat_interval = "5m";
        receiver = "default";
      };
      receivers = [
        {
          name = "default";
          webhook_configs = [ { url = "http://127.0.0.1:8378"; } ];
        }
      ];
    };
  };
  services.vmalert.instances.main = {
    enable = true;
    settings."datasource.url" = "http://localhost:8428/victoriametrics";
    settings."notifier.url" = [
      "http://127.0.0.1:${builtins.toString (config.services.prometheus.alertmanager.port)}/alertmanager"
    ];
    settings."http.pathPrefix" = "/vmalert";
    settings."external.url" = "https://${fqdn}";
    settings."external.alert.source" = alertSource;
    rules = {
      groups = (import ./alert-rules.nix) { };
    };
  };
  sops.secrets.oauth-proxy = {
    sopsFile = ./secrets.yaml;
    key = "oauth_proxy";
  };
  services.oauth2-proxy = {
    enable = true;
    clientID = "KRsIrVxFDXozPThUg7s08sPssHXiIXFLNszayZZ0";
    keyFile = config.sops.secrets.oauth-proxy.path;
    provider = "oidc";
    oidcIssuerUrl = "https://sso.c3voc.de/application/o/monitoring/";
    loginURL = "https://sso.c3voc.de/application/o/authorize/";
    redirectURL = "https://monitoring.c3voc.de/oauth2/callback";
    reverseProxy = true;
    setXauthrequest = true;
    email.domains = [ "*" ];
    extraConfig = {
      whitelist-domain = [ "monitoring.c3voc.de" ];
      insecure-oidc-allow-unverified-email = true;
      banner = "Sign in with VOC SSO";
      # custom-sign-in-logo = ./voctocat-black.svg;
      footer = "-";
    };
  };
}
