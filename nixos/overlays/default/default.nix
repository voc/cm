final: prev: {
  python310 = let packageOverrides = final: prev: import ./python final prev;
  in prev.python310.override { inherit packageOverrides; };

  yate = prev.yate.overrideAttrs (old: {
    configureFlags =
      [ "--with-libpq=${final.postgresql.withPackages (ps: [ ])}" ];
  });
}
