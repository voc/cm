{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.voc-loadbalancer;
  fqdn = config.networking.hostName + "." + config.networking.domain;
  haproxyCfg = pkgs.writeText "haproxy.conf" ''
    global
        # needed for hot-reload to work without dropping packets in multi-worker mode
        stats socket /run/haproxy/haproxy.sock mode 600 expose-fd listeners level user

        ulimit-n 1048576
        maxconn 500000
        maxconnrate 500000
        maxcomprate 0
        maxcompcpuusage 100
        maxsessrate 500000

        # TCP and Request Buffering
        tune.bufsize 262144
        tune.rcvbuf.client 262144
        tune.rcvbuf.server 2097152
        tune.sndbuf.client 2097152
        tune.sndbuf.server 262144

        # cors responder
        tune.lua.bool-sample-conversion normal
        lua-load ${./cors.lua}

        daemon
        log     /dev/log local0 notice
        # tls
        ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
        ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
        ssl-default-bind-options prefer-client-ciphers no-sslv3 no-tlsv10 no-tlsv11 no-tls-tickets

        ssl-default-server-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
        ssl-default-server-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
        ssl-default-server-options no-sslv3 no-tlsv10 no-tlsv11 no-tls-tickets

        ca-base /etc/ssl/certs

    defaults
        log     global
        maxconn 500000
        mode    http
        # enable some useful options
        option  socket-stats
        option  httplog
        option  dontlognull
        option  http-server-close
        option  abortonclose
        # configure timeouts
        timeout http-request 5s # avoid slowloris
        timeout connect 5s
        timeout server  10s
        timeout client  30s
        # custom error filter
        errorfile 500 ${./errorpages/500.html}
        errorfile 502 ${./errorpages/502.html}
        errorfile 503 ${./errorpages/503.html}
        log     /dev/log local0 notice

    frontend prometheus
        bind 127.0.0.1:9101
        mode http
        http-request set-log-level silent
        http-request use-service prometheus-exporter

    frontend icecast_and_nginx_hls_http
        bind 0.0.0.0:80
        bind :::80

        # add special header for protocol version
        http-request add-header X-Proto http  if !{ ssl_fc }

        ${frontendAcls "http"}

    frontend icecast_and_nginx_hls_https
        bind 0.0.0.0:443 ssl crt /var/lib/acme/${fqdn}/full.pem # <cert+privkey+intermediate+dhparam>
        bind :::443 ssl crt /var/lib/acme/${fqdn}/full.pem # <cert+privkey+intermediate+dhparam>

        tcp-request inspect-delay 5s

        stick-table type ip size 200k expire 1m store conn_rate(10s)
        tcp-request session track-sc0 src
        tcp-request session reject if { sc0_sess_rate gt 50 }

        # add special header for protocol version
        http-request add-header X-Proto https if  { ssl_fc }
        # HSTS
        http-response set-header Strict-Transport-Security "max-age=31536000" if { ssl_fc }

        ${frontendAcls "https"}

    # ######## #
    # BACKENDs #
    # ######## #

    # Streaming Website
    backend streaming_website_https
        balance source
        option forwardfor
        http-request set-header X-Custom-Header %[url]
        http-request set-header X-Real-IP %[src]
        server localhost 127.0.0.1:8080 maxconn 500000

    ## Templated by consul-template ##
    ${backends "http"}
    ${backends "https"}
  '';

  frontendAcls =
    proto:
    let
      ssl = if proto == "https" then "{ ssl_fc }" else "";
    in
    ''
          # header and path matching
        # tag request for the right destination server
          acl stream_file          path_end   -i .m3u8 .mpd .webm .m4s .ts .jpeg
          acl stream_path          path_dir   -i dash hls thumbnail
          acl is_relive            path_sub   -i index.json thumb.jpg sprites.jpg crossdomain.xml .mp4 relive
          acl is_stats             path_beg   -i /stats
          acl icecast              path_end   -i .webm .opus .mp3 .ogg .ogv .oga
          acl is_cdn               hdr_beg(host)  -i cdn.c3voc.de
          acl is_streaming_website hdr_beg(host)  -i streaming.media.ccc.de -i www.stream.c3voc.de
          acl is_streaming_website path_end   -i logo.webm
          acl is_streaming_website path_sub   -i acme-challenge

          # ip address matching
          acl is_local             src        94.45.224.0/19 151.217.0.0/17 2001:67c:20a1::/48 # 37c3

      ${optionalString cfg.dtagExtrawurst ''
            # dtag address matching
            acl is_dtag              src        -f ${./dtag_subnetworks.txt}
      ''}

          # return 403 if hostname or defined file extensions are not matching
          http-request deny        unless is_cdn or is_streaming_website
          http-request deny        unless stream_file or icecast or is_streaming_website or is_relive or is_stats

          ##
          # Backend usage
          ##
      ${
        if ssl == "" then
          ''
                # Redirect to https
                redirect scheme https code 301      if is_streaming_website ${ssl}
                redirect scheme https code 301      if is_relive ${ssl}
          ''
        else
          ''
                http-request use-service lua.cors-response if METH_OPTIONS { req.hdr(origin) -m found } { ssl_fc }
                use_backend streaming_website_https if is_streaming_website ${ssl}
                use_backend relive_https            if is_relive ${ssl}
          ''
      }

      [[- $numLocalHttp := service "local.http-relay" | len ]]
      [[- if gt $numLocalHttp 0 ]]
      [[- $numLocalHttps := service "local.https-relay" | len ]]
      [[- if gt $numLocalHttps 0 ]]
          # local relay
          use_backend local_${proto}       if is_local stream_path stream_file ${ssl}
          use_backend local_${proto}       if is_local icecast ${ssl}
      [[- end ]]
      [[- end ]]

      ${optionalString cfg.dtagExtrawurst ''
        # dtag relay
        use_backend dtag_${proto}        if is_dtag stream_path stream_file ${ssl}
        use_backend dtag_${proto}        if is_dtag icecast ${ssl}
      ''}

          # use remote relays
          use_backend nginx_${proto}       if stream_path stream_file ${ssl}
          use_backend icecast_${proto}     if icecast ${ssl}
          use_backend stats_${proto}       if is_stats ${ssl}
    '';
  backends = proto: ''

    # ${proto}
    # REMOTE
    backend nginx_${proto}
        balance source
        option forwardfor

    [[- $services${proto} := service "edge.${proto}-relay" ]]
    [[- range $services${proto} ]]
        [[- $name := .Node | replaceAll "-" "." ]]
        [[- $key := printf "services/haproxy/backends/%s/weight" $name ]]
        [[- $weight := keyOrDefault $key "100" ]]
        server [[ $name ]] [[ $name ]]:[[ .Port ]] redir ${proto}://[[ $name ]]:[[ .Port ]]  weight [[ $weight ]] check port [[ .Port ]][[ end ]]

    backend relive_${proto}
        balance source
        option forwardfor
    [[- range $services${proto} ]]
        [[- if in .Tags "relive" | not ]]
            [[- continue ]]
        [[- end ]]
        [[- $name := .Node | replaceAll "-" "." ]]
        [[- $key := printf "services/haproxy/backends/%s/weight" $name ]]
        [[- $weight := keyOrDefault $key "100" ]]
        server [[ $name ]] [[ $name ]]:[[ .Port ]] redir ${proto}://[[ $name ]]:[[ .Port ]]  weight [[ $weight ]] check port [[ .Port ]][[ end ]]

    backend icecast_${proto}
        balance source
        option forwardfor
    [[- range $services${proto} ]]
        [[- if in .Tags "icecast" | not ]]
            [[- continue ]]
        [[- end ]]
        [[- $name := .Node | replaceAll "-" "." ]]
        [[- $key := printf "services/haproxy/backends/%s/weight" $name ]]
        [[- $weight := keyOrDefault $key "100" ]]
        server [[ $name ]] [[ $name ]]:[[ .Port ]] redir ${proto}://[[ $name ]]:[[ .Port ]]  weight [[ $weight ]] check port [[ .Port ]][[ end ]]

    # LOCAL
    backend local_${proto}
        balance source
        option forwardfor
    [[- range $services${proto} ]]
        [[- if in .Tags "local" | not ]]
            [[- continue ]]
        [[- end ]]
        [[- $name := .Node | replaceAll "-" "." ]]
        [[- $key := printf "services/haproxy/backends/%s/weight" $name ]]
        [[- $weight := keyOrDefault $key "100" ]]
        server [[ $name ]] [[ $name ]]:[[ .Port ]] redir ${proto}://[[ $name ]]:[[ .Port ]]  weight [[ $weight ]] check port [[ .Port ]][[ end ]]


    ${optionalString cfg.dtagExtrawurst ''
      # DTAG EXTRAWURST
      backend dtag_${proto}
          balance source
          option forwardfor
      [[- range $services${proto} ]]
          [[- if in .Tags "dtag" | not ]]
              [[- continue ]]
          [[- end ]]
          [[- $name := .Node | replaceAll "-" "." ]]
          [[- $key := printf "services/haproxy/backends/%s/weight" $name ]]
          [[- $weight := keyOrDefault $key "100" ]]
          server [[ $name ]] [[ $name ]]:[[ .Port ]] redir ${proto}://[[ $name ]]:[[ .Port ]]  weight [[ $weight ]] check port [[ .Port ]][[ end ]]
    ''}

    # stats
    backend stats_${proto}
        balance source
        option forwardfor
    [[- range $services${proto} ]]
        [[- if in .Tags "stats" | not ]]
            [[- continue ]]
        [[- end ]]
        [[- $name := .Node | replaceAll "-" "." ]]
        [[- $key := printf "services/haproxy/backends/%s/weight" $name ]]
        [[- $weight := keyOrDefault $key "100" ]]
        server [[ $name ]] [[ $name ]]:[[ .Port ]] redir ${proto}://[[ $name ]]:[[ .Port ]]  weight [[ $weight ]] check port [[ .Port ]][[ end ]]

  '';
in
{
  imports = [ ../voc-haproxy ../streaming-website ];
  options = {
    services.voc-loadbalancer = {
      enable = mkEnableOption "voc-loadbalancer";
      dtagExtrawurst = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable the DTAG extrawurst ACLs and backends.";
      };
    };
  };

  config = mkIf cfg.enable {
    services.telegraf.extraConfig = {
      global_tags.role = "loadbalancer";
    };
    # run as nebula lighthouse
    services.voc-nebula = {
      enable = true;
      isLighthouse = true;
    };
    # run as consul server
    services.voc-consul = {
      enable = true;
      server = true;
      webUi = true;
    };
    services.voc-haproxy = {
      enable = true;
      configPath = "/etc/haproxy.cfg";
      limitNoFile = 1048576;
    };
    # template haproxy config
    services.consul-template.instances.haproxy = {
      settings = {
        template = [
          {
            source = haproxyCfg;
            destination = "/etc/haproxy.cfg";
            command = "systemctl reload haproxy";
            left_delimiter = "[[";
            right_delimiter = "]]";
          }
        ];
      };
    };
    # read haproxy metrics
    services.telegraf.extraConfig = {
      inputs = {
        prometheus = [{
          urls = [ "http://localhost:9101/metrics" ];
          metric_version = 1;
          tags = {
            job = "haproxy";
          };
        }];
      };
    };

    services.streaming-website = {
      enable = true;
    };

    sops.secrets.lednsapi = {
      sopsFile = ./secrets.yaml;
      key = "lednsapi/${fqdn}";
      owner = config.users.users.acme.name;
    };

    # Generate and renew TLS certificates via ACME (Let's Encrypt)
    security.acme.certs."${fqdn}" = {
      # server = "https://acme-staging-v02.api.letsencrypt.org/directory";
      dnsProvider = "exec";
      email = "contact@c3voc.de";
      group = "nginx";
      reloadServices = [ "haproxy.service" ];
      extraDomainNames = [
        "cdn.c3voc.de"
        "streaming.media.ccc.de"
      ];
      environmentFile =
        let
          script = pkgs.writeShellScript "ledns-challenge.sh" (
            import ./ledns-challenge.nix {
              curl = pkgs.curl;
              secretpath = config.sops.secrets.lednsapi.path;
            }
          );
        in
        pkgs.writeText "env" ''
          EXEC_PATH=${script}
        '';
      postRun = ''
        # set permission on dir
        ${pkgs.acl}/bin/setfacl -m \
        u:haproxy:rx \
        /var/lib/acme/${fqdn}

        # set permission on key file
        ${pkgs.acl}/bin/setfacl -m \
        u:haproxy:r \
        /var/lib/acme/${fqdn}/*.pem
      '';
    };

    # open the gates
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };
}
