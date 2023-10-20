nixpkgs: self: super: {
  diffsync = self.callPackage ./diffsync { };
  python-yate = self.callPackage ./python-yate { };
  ywsd = self.callPackage ./ywsd { };
  mitel-ommclient2 = self.callPackage ./mitel-ommclient2 { };
  fieldpoc = self.callPackage ./fieldpoc { };
  django-admin-autocomplete-filter = self.callPackage ./django-admin-autocomplete-filter { };
  django-bootstrap5 = self.callPackage ./django-bootstrap5 { };
  django-verify-email = self.callPackage ./django-verify-email { };
  nerd = self.callPackage ./nerd { };

  python3-saml = super.python3-saml.overrideAttrs (prev: {
    patches = __trace "python3-saml: REMOVE OVERRIDE WHEN https://github.com/NixOS/nixpkgs/pull/262342 has been merged" [
      (nixpkgs.fetchpatch {
        name = "test-expired.patch";
        url = "https://github.com/SAML-Toolkits/python3-saml/commit/bd65578e5a21494c89320094c61c1c77250bea33.diff";
        hash = "sha256-9Trew6R5JDjtc0NRGoklqMVDEI4IEqFOdK3ezyBU6gI=";
      })
      (nixpkgs.fetchpatch {
        name = "test-expired.patch";
        url = "https://github.com/SAML-Toolkits/python3-saml/commit/ea3a6d4ee6ea0c5cfb0f698d8c0ed25638150f47.patch";
        hash = "sha256-Q9+GM+mCEZK0QVp7ulH2hORVig2411OvkC4+o36DeXg=";
      })
      (nixpkgs.fetchpatch {
        name = "test-expired.patch";
        url = "https://github.com/SAML-Toolkits/python3-saml/commit/feb0d1d954ee4d0ad1ad1d7d536bf9e83fa9431b.patch";
        hash = "sha256-NURGI4FUnFlWRZfkioU9IYmZ+Zk9FKfZchjdn7N9abU=";
      })
    ];
  });
}
