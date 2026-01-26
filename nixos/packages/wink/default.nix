{ lib
, stdenv
, bundlerEnv
, ruby_3_3
, nodejs
, sqlite
, postgresql
, libxml2
, libxslt
, zlib
, libyaml
, openssl
, pkg-config
, fetchFromGitHub
, libsass
, libffi
}:

let
  ruby = ruby_3_3;

  gems = bundlerEnv {
    name = "wink-gems";
    inherit ruby;
    gemdir = ./.;

    gemConfig = {
      pg = attrs: {
        buildInputs = [ postgresql ];
        nativeBuildInputs = [ pkg-config ];
      };
      sqlite3 = attrs: {
        buildInputs = [ sqlite ];
        nativeBuildInputs = [ pkg-config ];
      };
      nokogiri = attrs: {
        buildInputs = [ libxml2 libxslt zlib ];
        nativeBuildInputs = [ pkg-config ];
      };
      ffi = attrs: {
        nativeBuildInputs = [ pkg-config libffi ];
      };
      psych = attrs: {
        buildInputs = [ libyaml ];
        nativeBuildInputs = [ pkg-config ];
      };
      sassc = attrs: {
        buildInputs = [ libsass ];
        nativeBuildInputs = [ pkg-config ];
      };
      puma = attrs: {
        buildInputs = [ openssl ];
        nativeBuildInputs = [ pkg-config ];
      };
    };
  };

  src = fetchFromGitHub {
    owner = "voc";
    repo = "wink";
    rev = "master";
    hash = "sha256-lT9V+wTpNaClHbS7C9gpwKRXaYU2aKbJD0rcajRt7Bw=";
  };

in
stdenv.mkDerivation rec {
  pname = "wink";
  version = "unstable-2025";

  inherit src;

  nativeBuildInputs = [ pkg-config nodejs ];
  buildInputs = [ gems gems.wrappedRuby sqlite ];

  RAILS_ENV = "production";
  SECRET_KEY_BASE = "dummy-for-asset-precompilation";
  DISABLE_BOOTSNAP = "1";

  postPatch = ''
    cp config/mqtt.yml.template config/mqtt.yml
    
    cat > config/database.yml << 'EOF'
  default: &default
    adapter: postgresql
    encoding: unicode
    pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
    host: <%= ENV.fetch("DATABASE_HOST", "localhost") %>
    username: <%= ENV.fetch("DATABASE_USER", "wink") %>
    password: <%= ENV.fetch("DATABASE_PASSWORD", "") %>

  development:
    <<: *default
    database: wink_development

  test:
    <<: *default
    database: wink_test

  production:
    primary:
      <<: *default
      database: <%= ENV.fetch("DATABASE_NAME", "wink_production") %>
    cache:
      <<: *default
      database: <%= ENV.fetch("CACHE_DATABASE_NAME", "wink_cache") %>
      migrations_paths: db/cache_migrate
    queue:
      <<: *default
      database: <%= ENV.fetch("QUEUE_DATABASE_NAME", "wink_queue") %>
      migrations_paths: db/queue_migrate
    cable:
      <<: *default
      database: <%= ENV.fetch("CABLE_DATABASE_NAME", "wink_cable") %>
      migrations_paths: db/cable_migrate
  EOF
  '';

  buildPhase = ''
    runHook preBuild
    mkdir -p tmp/cache log
    ${gems}/bin/bundle exec rails assets:precompile
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/wink
    cp -r . $out/share/wink/

    rm -rf $out/share/wink/{.git,.github,tmp,log,spec,test,coverage}
    mkdir -p $out/share/wink/{tmp,log,storage}

    mkdir -p $out/bin

    cat > $out/bin/wink-server <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
export PATH="${gems}/bin:${gems.wrappedRuby}/bin:$PATH"
cd ${placeholder "out"}/share/wink
exec bundle exec puma -C config/puma.rb "$@"
SCRIPT

    cat > $out/bin/wink-console <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
export PATH="${gems}/bin:${gems.wrappedRuby}/bin:$PATH"
cd ${placeholder "out"}/share/wink
exec bundle exec rails console "$@"
SCRIPT

    cat > $out/bin/wink-rake <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
export PATH="${gems}/bin:${gems.wrappedRuby}/bin:$PATH"
cd ${placeholder "out"}/share/wink
exec bundle exec rake "$@"
SCRIPT

    cat > $out/bin/wink-rails <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
export PATH="${gems}/bin:${gems.wrappedRuby}/bin:$PATH"
cd ${placeholder "out"}/share/wink
exec bundle exec rails "$@"
SCRIPT

    cat > $out/bin/wink-jobs <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
export PATH="${gems}/bin:${gems.wrappedRuby}/bin:$PATH"
cd ${placeholder "out"}/share/wink
exec bundle exec rails solid_queue:start "$@"
SCRIPT

    chmod +x $out/bin/*

    runHook postInstall
  '';

  passthru = { inherit gems ruby; };

  meta = with lib; {
    description = "Wink - C3VOC inventory and transport planning";
    homepage = "https://github.com/voc/wink";
    license = licenses.bsd2;
    platforms = platforms.linux;
  };
}
