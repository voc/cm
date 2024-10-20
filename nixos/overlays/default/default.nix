final: prev: {
  python39 = let packageOverrides = pfinal: pprev: import ./python final pfinal pprev;
  in prev.python39.override { inherit packageOverrides; };
  python310 = let packageOverrides = pfinal: pprev: import ./python final pfinal pprev;
  in prev.python310.override { inherit packageOverrides; };
  python311 = let packageOverrides = pfinal: pprev: import ./python final pfinal pprev;
  in prev.python311.override { inherit packageOverrides; };

  yate = prev.yate.overrideAttrs (old: {
    configureFlags =
      [ "--with-libpq=${final.postgresql.withPackages (ps: [ ])}" ];
  });
  rt = prev.rt.overrideAttrs (old: {
    patches = old.patches ++ [ ./rt/rt-server-fcgi-wrapper.patch ];
  });
}
