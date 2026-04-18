final: prev: {
  python39 = let packageOverrides = pfinal: pprev: import ./python final pfinal pprev;
  in prev.python39.override { inherit packageOverrides; };
  python310 = let packageOverrides = pfinal: pprev: import ./python final pfinal pprev;
  in prev.python310.override { inherit packageOverrides; };
  python311 = let packageOverrides = pfinal: pprev: import ./python final pfinal pprev;
  in prev.python311.override { inherit packageOverrides; };
  python312 = let packageOverrides = pfinal: pprev: import ./python final pfinal pprev;
  in prev.python312.override { inherit packageOverrides; };
  python313 = let packageOverrides = pfinal: pprev: import ./python final pfinal pprev;
  in prev.python313.override { inherit packageOverrides; };

  yate = prev.yate.overrideAttrs (old: {
    configureFlags =
      [ "--with-libpq=${final.postgresql.withPackages (ps: [ ])}" ];
  });
  rt = prev.rt.overrideAttrs (old: {
    patches = old.patches ++ [ ./rt/rt-server-fcgi-wrapper.patch ];
  });
  haproxy = prev.haproxy.overrideAttrs (old: {
    patches = [ ./haproxy/redirect-with-cors.patch ];
  });
  stream-api = prev.callPackage ./stream-api.nix { };
  voc-telemetry = prev.callPackage ./voc-telemetry.nix { };
  voc2mqtt-tools = prev.callPackage ./voc2mqtt-tools.nix { };
  ripe-mmdb = prev.callPackage ./ripe-mmdb.nix { };
  srtrelay = prev.callPackage ./srtrelay.nix { };
  rtmp-auth = prev.callPackage ./rtmp-auth.nix { };

  AnyEventMQTT = prev.callPackage ./AnyEventMQTT.nix { };
  NetMQTT = prev.callPackage ./NetMQTT.nix { };
  mqtt-watchdog = prev.callPackage ./mqtt-watchdog { };
}
