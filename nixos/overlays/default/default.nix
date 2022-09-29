final: prev: {
  python3 = let packageOverrides = final: prev: import ./python final prev;
  in prev.python3.override { inherit packageOverrides; };
  python39 = let packageOverrides = final: prev: import ./python final prev;
  in prev.python39.override { inherit packageOverrides; };

  yate = prev.yate.overrideAttrs (old: {
    configureFlags =
      [ "--with-libpq=${final.postgresql.withPackages (ps: [ ])}" ];
  });
}
