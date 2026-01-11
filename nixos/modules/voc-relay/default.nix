{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.voc-relay;
  fqdn = config.networking.hostName + "." + config.networking.domain;
  caches = ''
    # Caching directories
    proxy_temp_path /var/cache/nginx/tmp;

    ${optionalString (!cfg.isReliveOrigin) ''
      proxy_cache_path /var/cache/nginx/hls_relive
        keys_zone=hls_relive:32m
        max_size=${cfg.reliveCacheSize}
        inactive=7d
        loader_threshold=300 loader_files=1024;
    ''}
    ${optionalString (!cfg.isOrigin) ''
      proxy_cache_path /var/cache/nginx/live
        keys_zone=live:32m
        max_size=${cfg.liveCacheSize}
        inactive=10m
        loader_threshold=300 loader_files=1024;

      proxy_cache_path /var/cache/nginx/mediastatic
        keys_zone=mediastatic:32m
        max_size=${cfg.mediaStaticCacheSize}
        inactive=6h
        loader_threshold=300 loader_files=1024;
    ''}
  '';
  upstreams = ''
    # Upstreams
    upstream stream {
      # Templated by consul-template
    [[- range $index,$service := service "relay_origin.http-relay" ]]
      server [[ $service.Address ]]:[[ $service.Port ]]
      [[- if gt $index 0 ]] backup[[ end ]]; # [[ $service.Node ]][[ end ]]

      # backup server to prevent reload fail
      server localhost:123 down;
      keepalive 32;
    }

    upstream relive {
      # Templated by consul-template
    [[- range service "relive_origin.http-relay" ]]
      server [[ .Address ]]:[[ .Port ]]; # [[ .Node ]][[ end ]]

      # backup server to prevent reload fail
      server localhost:123 down;
      keepalive 32;
    }

    upstream mediastatic {
    ${concatStringsSep "\n" (
      map (host: "  server ${host}:443;") cfg.mediaStaticBackends
    )}
    }

    upstream icecast {
      server localhost:8000;
      keepalive 1000;
    }
  '';

  proxyCommon = ''
    proxy_intercept_errors on;
    proxy_cache_methods    HEAD GET;
    proxy_cache_revalidate on;
    proxy_cache_key        "$uri";
    proxy_cache_lock       on; # prevent thundering herd on cache miss
    proxy_ignore_headers   Cache-Control;

    # client caching
    add_header Cache-Control no-cache;
    add_header X-Cache     "$upstream_cache_status edge";
    add_header Access-Control-Expose-Headers "X-Host";
    add_header X-Host "${fqdn}";

    # log for viewer counting
    access_log syslog:server=unix:/var/log/relay.sock json_logs;
  '';

  configFile = pkgs.writeText "voc-relay.conf" ''
    ## Templated at runtime by consul-template
    ${caches}

    ${upstreams}

    # relay vhost
    server {
      server_name _;
      listen [::]:80 default_server ipv6only=off;
      listen [::]:443 default_server ipv6only=off ssl;
      http2 on;

      root /var/www;
      index index.html;

      add_header Access-Control-Allow-Origin "*" always;
      # TLS certificates
      ssl_certificate       /var/lib/acme/${fqdn}/fullchain.pem;
      ssl_certificate_key   /var/lib/acme/${fqdn}/key.pem;

      # don't allow access to some files or directories
      location ~* /.*\.(ht|sh|git|htaccess|php|inc|rb|py|pl|db|sqlite|sqlite3)$ {
        deny  all;
      }

      # ACME http challenge
      location ^~ /.well-known/acme-challenge {
        root /var/lib/acme/.challenges;
      }

      # health endpoint
      location = /health {
        access_log off;
        add_header 'Content-Type' 'application/json';
        return 200 '{"status": "up"}';
      }

      ${if cfg.isOrigin then ''
        # stream-api
        location /stream_info.json {
          auth_basic           "voc login";
          auth_basic_user_file htpasswd;
          alias /srv/nginx/stream_info.json;
        }

        location ~* ^/(consul|v1)/(.+)?$ {
          auth_basic "voc login";
          auth_basic_user_file htpasswd;
          proxy_pass http://localhost:8500;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
        }

        location ~* ^/upload/(?<path>.+)?$ {
          proxy_pass http://127.0.0.1:8080/$path;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          client_max_body_size 100M;
          keepalive_requests 200;
          #access_log /var/log/nginx/upload.log;
        }

        location ~* ^/(hls|dash|thumbnail|artwork)/(.+)?$ {
          alias /srv/nginx/$1/$2;
          autoindex off;
        }
      '' else ''
        # proxy cache hls playlist (live)
        #
        # live:   /hls/s2_native_sd.m3u8
        #
        location ~* ^/(?<hls>hls)/(?<file>.+\.m3u8)$ {
          proxy_cache            live;
          proxy_pass             http://stream/$hls/$file;
          proxy_cache_valid      200 302 1s;
          ${proxyCommon}
        }

        # proxy cache dash manifests (live)
        #
        # live:   /dash/s2.mpd
        #
        location ~* ^/dash/(?<manifest>.+\.mpd)$ {
          proxy_cache            live;
          proxy_pass             http://stream/dash/$manifest;
          proxy_cache_valid      200 302 1s;
          ${proxyCommon}
        }

        # proxy cache segments (live)
        #
        # live hls:         /hls/s2/1606696682-1049_2.ts for ts-hls
        # init-segment:     /dash/s2-i1.hdr
        # chunk-segments:   /dash/s2-s1-00041.webm for WebM-dash or
        #                   /dash/s2-s1-00041.m4s for MP4-dash
        #
        location ~* ^/(?<proto>hls|dash)/(?<stream>.+\.(ts|hdr|webm|m4s))$ {
          proxy_cache            live;
          proxy_pass             http://stream/$proto/$stream;
          proxy_cache_valid      200 302 5m;
          ${proxyCommon}
        }

        # proxy thumbnails/posters (live)
        #
        # live:   /thumbnail/s1/poster.jpeg
        #
        location ~* ^/thumbnail/(?<thumbnail>.+\.jpeg)$ {
          proxy_cache            live;
          proxy_pass             http://stream/thumbnail/$thumbnail;
          proxy_cache_valid      200 302 5s;
          ${proxyCommon}
        }

        # Icecast direct proxy path for https streaming
        #
        location ~* ^/.*\.(webm|mp3|opus)$ {
          proxy_buffering        off;
          proxy_pass             http://icecast;
        }

        # proxy cache static media files
        #
        # relive: /media/congress/2019/11224-hd.jpg
        #
        location ~* ^/(?<media>media)/(?<file>.+)$ {
          proxy_cache            mediastatic;
          proxy_set_header       Host static.media.ccc.de;
          proxy_pass             https://mediastatic/$media/$file;
          proxy_cache_valid      200 302 1d;
          # allow stale
          proxy_cache_use_stale error timeout updating http_500 http_502
                                http_503 http_504;
          proxy_cache_background_update on;
          # common
          ${proxyCommon}
        }
      ''}

      ${if cfg.isReliveOrigin then ''
        # relive
        location ~ ^/crossdomain.xml {
          alias /srv/nginx/relive/crossdomain.xml;
          include /etc/nginx/mime.types;
        }

        location ~* ^/relive/(.+\.ts)$ {
          alias /srv/nginx/relive/$1;
        }

        location ~* ^/relive/(.*) {
          alias /srv/nginx/relive/$1;
          autoindex on;
        }
      '' else ''
        # proxy cache m3u8 (relive) and index.json (relive)
        #
        # relive: /relive/nixcon2015/19/index.m3u8
        #         /relive/nixcon2015/index.json
        #
        #
        location ~* ^/(?<hls_relive>relive)/(?<file>.+(\.m3u8|index\.json))$ {
          proxy_cache            hls_relive;
          proxy_pass             http://relive/$hls_relive/$file;
          proxy_cache_valid      200 302 1s;
          ${proxyCommon}
        }

        # proxy cache ts files (relive)
        #
        # relive: /relive/31c3/29/1016.ts
        #
        location ~* ^/(?<hls_relive>relive)/(?<stream>.+\.ts)$ {
          proxy_cache            hls_relive;
          proxy_pass             http://relive/$hls_relive/$stream;
          proxy_cache_valid      200 302 1h;
          ${proxyCommon}
        }

        # proxy cache mp4 files (relive)
        #
        # relive: /relive/32c3/29/muxed.mp4
        #
        location ~* ^/(?<hls_relive>relive)/(?<stream>.+muxed\.mp4)$ {
          proxy_cache            hls_relive;
          proxy_pass             http://relive/$hls_relive/$stream;
          proxy_cache_valid      200 302 1h;

          # limit dl rate
          limit_rate 20m;

          # common
          proxy_intercept_errors on;
          proxy_cache_methods    HEAD GET;
          proxy_cache_lock       on; # prevent thundering herd on cache miss

          # client caching
          add_header X-Cache     "$upstream_cache_status edge";
        }

        # proxy cache for:
        #  * thumbs             (relive)
        #  * sprites            (relive)
        #  * index.html         (relive)
        #  * crossdomain.xml    (relive)
        #
        # relive: /crossdomain.xml
        #         /relive/33c3/29/thumb.jpg
        #         /relive/33c3/index.html
        #
        location ~* ^/(crossdomain\.xml|relive.+thumb\.jpg|.+index\.html|relive.+sprites\.jpg|relive.+sprites\.jpg\.meta)$ {
          proxy_cache            hls_relive;
          proxy_pass             http://relive/$1;
          proxy_cache_valid      200 302 5m;
          ${proxyCommon}
        }
      ''}

      location = /stats/ {
        add_header Access-Control-Allow-Origin  "*";
        add_header Access-Control-Allow-Headers "Content-Type";
        add_header Access-Control-Allow-Methods "POST";
        proxy_pass http://localhost:2342/;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
      }
    }
  '';
in {
  options = {
    services.voc-relay = {
      enable = mkEnableOption "voc-relay";
      isOrigin = mkOption {
        type = types.bool;
        default = false;
        description = ''Whether this node should act as an origin server.'';
      };
      isReliveOrigin = mkOption {
        type = types.bool;
        default = false;
        description = ''Whether this node should act as a relive origin server.'';
      };
      reliveCacheSize = mkOption {
        type = types.str;
        default = "10g";
        description = ''Size of the relive cache.'';
      };
      liveCacheSize = mkOption {
        type = types.str;
        default = "5g";
        description = ''Size of the live cache.'';
      };
      mediaStaticCacheSize = mkOption {
        type = types.str;
        default = "1g";
        description = ''Size of the media static cache.'';
      };
      mediaStaticBackends = mkOption {
        type = types.listOf types.str;
        default = [ "212.201.68.132" ];
        description = ''List of backend hosts for media static content.'';
      };
    };
  };

  config = mkIf cfg.enable {
    services.telegraf.extraConfig = {
      global_tags.role = if cfg.isOrigin then "master-relay" else "edge-relay";
    };
    # enable nebula
    services.voc-nebula = {
        enable = true;
    };
    # enable consul
    services.voc-consul = {
      enable = true;
    };
    services.nginx = {
      enable = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;
      sslProtocols = "TLSv1.2 TLSv1.3";
      commonHttpConfig = ''
        resolver 127.0.0.53;

        # disable directory listing
        autoindex off;

        log_format json_logs escape=json '{'
          '"time_local": "$time_local",'
          '"remote_addr": "$remote_addr",'                            # client IP
          '"method": "$request_method",'                              # request method, usually “GET” or “POST”
          '"protocol": "$server_protocol",'                           # request protocol, usually “HTTP/1.0”, “HTTP/1.1”, “HTTP/2.0”, or “HTTP/3.0”
          '"uri": "$uri",'                                            # current URI in request
          '"status": "$status",'                                      # response status code
          '"bytes_sent": "$bytes_sent", '                             # the number of bytes sent to a client
          '"request_length": "$request_length", '                     # request length (including headers and body)
          '"connection_requests": "$connection_requests",'            # number of requests made in connection
          '"upstream": "$upstream_addr", '                            # upstream backend server for proxied requests
          '"upstream_connect_time": "$upstream_connect_time", '       # upstream handshake time incl. TLS
          '"upstream_header_time": "$upstream_header_time", '         # time spent receiving upstream headers
          '"upstream_response_time": "$upstream_response_time", '     # time spend receiving upstream body
          '"upstream_response_length": "$upstream_response_length", ' # upstream response length
          '"upstream_cache_status": "$upstream_cache_status", '       # cache HIT/MISS where applicable
          '"ssl_protocol": "$ssl_protocol", '                         # TLS protocol
          '"ssl_cipher": "$ssl_cipher", '                             # TLS cipher
          '"scheme": "$scheme", '                                     # http or https
          '"user_agent": "$http_user_agent"'
        '}';
      '';
      # vhost for stats
      appendHttpConfig = ''
        server {
          server_name _;
          listen 127.0.0.1:8999;
          # stats
          location = /stats/nginx {
            stub_status on;
            access_log  off;
            allow ::1;
            allow 127.0.0.1;
            deny all;
          }
        }
        include /etc/nginx/*.conf;
      '';
    };
    services.consul-template.instances.nginx = {
      settings = {
        template = [{
          source = configFile;
          destination = "/etc/nginx/voc-relay.conf";
          command = "systemctl reload nginx";
          left_delimiter = "[[";
          right_delimiter = "]]";
        }];
      };
    };
    # Read Nginx's basic status information (ngx_http_stub_status_module)
    services.telegraf.extraConfig.inputs.nginx = {
      urls = ["http://localhost:8999/stats/nginx"];
    };
    # Generate and renew TLS certificates via ACME (Let's Encrypt)
    security.acme.certs."${fqdn}" = {
      webroot = "/var/lib/acme/.challenges";
      email = "contact@c3voc.de";
      group = "nginx";
      reloadServices = ["nginx.service"];
    };
    networking.firewall.allowedTCPPorts = [80 443];
  };
}
