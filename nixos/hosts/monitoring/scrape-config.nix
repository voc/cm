{
  pkgs,
  lib,
  config,
  vmalertPort,
}:
let
  allHosts = map (name: nameToHost name) (
    lib.attrNames (
      lib.filterAttrs (
        host: deriv: host != config.networking.hostName && !lib.elem "lan" (getTags host (deriv { }))
      ) (import ./../../hosts.nix)
    )
  );
  hostsByTag =
    tag:
    map (name: nameToHost name) (
      lib.attrNames (
        lib.filterAttrs (host: deriv: lib.elem tag (getTags host (deriv { }))) (import ./../../hosts.nix)
      )
    );
  getTags =
    name: conf:
    if
      lib.hasAttrByPath [
        "deployment"
        "tags"
      ] conf
    then
      conf.deployment.tags
    else
      [ ];
  nameToHost = name: (builtins.replaceStrings [ "-" ] [ "." ] name) + ".c3voc.de";
  blackboxAddr = "localhost:${builtins.toString (config.services.prometheus.exporters.blackbox.port)}";
  scrapeConfig = [
    {
      job_name = "blackbox-hls";
      file_sd_configs = [ { files = [ "/var/lib/victoriametrics/streams.yml" ]; } ];
      metrics_path = "/probe";
      params = {
        module = [ "http" ];
      };
      relabel_configs = [
        {
          source_labels = [ "__address__" ];
          replacement = "http://live.ber.c3voc.de/hls/$1/native_hd.m3u8";
          target_label = "__param_target";
        }
        {
          source_labels = [ "__address__" ];
          target_label = "stream";
        }
        {
          target_label = "__address__";
          replacement = blackboxAddr;
        }
      ];
    }
    {
      job_name = "blackbox-ipv4";
      static_configs = [ { targets = allHosts; } ];
      metrics_path = "/probe";
      params = {
        module = [ "icmpv4" ];
      };
      relabel_configs = [
        {
          source_labels = [ "__address__" ];
          target_label = "__param_target";
        }
        {
          source_labels = [ "__param_target" ];
          target_label = "instance";
        }
        {
          target_label = "__address__";
          replacement = blackboxAddr;
        }
      ];
    }
    {
      job_name = "blackbox-ipv6";
      static_configs = [ { targets = allHosts; } ];
      metrics_path = "/probe";
      params = {
        module = [ "icmpv6" ];
      };
      relabel_configs = [
        {
          source_labels = [ "__address__" ];
          target_label = "__param_target";
        }
        {
          source_labels = [ "__param_target" ];
          target_label = "instance";
        }
        {
          target_label = "__address__";
          replacement = blackboxAddr;
        }
      ];
    }
    {
      job_name = "alertmanager";
      static_configs = [
        { targets = [ "localhost:${builtins.toString config.services.prometheus.alertmanager.port}" ]; }
      ];
      metrics_path = "/alertmanager/metrics";
    }
    {
      job_name = "vmalert";
      static_configs = [ { targets = [ "localhost:${vmalertPort}" ]; } ];
      metrics_path = "/vmalert/metrics";
    }
  ];
  settingsFormat = pkgs.formats.yaml { };
  settingsFile = settingsFormat.generate "prometheus.yaml" {
    global = {
      scrape_interval = "10s";
      scrape_timeout = "10s";
    };
    scrape_configs = scrapeConfig;
  };
  # Do the config check here manually, because the upstream victoriametrics module doesn't support promscrape config reload
  checkedConfig =
    file:
    pkgs.runCommand "checked-config" { nativeBuildInputs = [ pkgs.victoriametrics ]; } ''
      ln -s ${file} $out
      ${pkgs.victoriametrics}/bin/victoria-metrics -promscrape.config=${file} -dryRun
    '';
in
checkedConfig settingsFile
