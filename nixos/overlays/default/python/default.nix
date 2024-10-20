nixpkgs: self: super: {
  python-yate = self.callPackage ./python-yate { };
  ywsd = self.callPackage ./ywsd { };
  mitel-ommclient2 = self.callPackage ./mitel-ommclient2 { };
  fieldpoc = self.callPackage ./fieldpoc { };
  django-admin-autocomplete-filter = self.callPackage ./django-admin-autocomplete-filter { };
  django-bootstrap5 = self.callPackage ./django-bootstrap5 { };
  django-verify-email = self.callPackage ./django-verify-email { };
  nerd = self.callPackage ./nerd { };
  aiopg = self.callPackage ./aiopg { };
}
